# Data source for latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Security Group
resource "aws_security_group" "atlantis" {
  name_prefix = "${var.project_name}-sg-"
  description = "Security group for Atlantis server"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "SSH access"
  }

  # Atlantis web interface
  ingress {
    from_port   = var.atlantis_port
    to_port     = var.atlantis_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Atlantis web interface"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# IAM Role for EC2
resource "aws_iam_role" "atlantis" {
  name = "${var.project_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-role"
  }
}

# IAM Policy for Atlantis (add permissions as needed)
resource "aws_iam_role_policy" "atlantis" {
  name = "${var.project_name}-policy"
  role = aws_iam_role.atlantis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "atlantis" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.atlantis.name
}

# SSH Key Pair
resource "aws_key_pair" "atlantis" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key
}

# Launch Template for Spot Instance
resource "aws_launch_template" "atlantis" {
  count         = var.use_spot_instance ? 1 : 0
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.ssh_public_key != "" ? aws_key_pair.atlantis[0].key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.atlantis.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.atlantis.id]
    delete_on_termination       = true
  }

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.spot_price
      # Using one-time for cost optimization - instance will not be automatically restarted if interrupted
      # For production, consider using 'persistent' with proper handling of interruptions
      spot_instance_type = "one-time"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    atlantis_version = var.atlantis_version
    atlantis_port    = var.atlantis_port
    github_user      = var.github_user
    github_token     = var.github_token
    webhook_secret   = var.github_webhook_secret
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-spot-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Spot Instance
resource "aws_instance" "atlantis_spot" {
  count = var.use_spot_instance ? 1 : 0

  launch_template {
    id      = aws_launch_template.atlantis[0].id
    version = "$Latest"
  }

  subnet_id = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-spot-instance"
  }
}

# On-Demand Instance (fallback)
resource "aws_instance" "atlantis_ondemand" {
  count                  = var.use_spot_instance ? 0 : 1
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.atlantis.id]
  iam_instance_profile   = aws_iam_instance_profile.atlantis.name
  key_name               = var.ssh_public_key != "" ? aws_key_pair.atlantis[0].key_name : null

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    atlantis_version = var.atlantis_version
    atlantis_port    = var.atlantis_port
    github_user      = var.github_user
    github_token     = var.github_token
    webhook_secret   = var.github_webhook_secret
  }))

  tags = {
    Name = "${var.project_name}-ondemand-instance"
  }
}
