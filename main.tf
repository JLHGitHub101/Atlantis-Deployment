###
data "aws_caller_identity" "current" {}

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

# IAM role for EC2:
# - SSM access (AmazonSSMManagedInstanceCore)
# - Read Secrets Manager
# - Admin access (for Terraform to manage infra)
resource "aws_iam_role" "atlantis" {
  name = "atlantis-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.atlantis.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Least-privilege IAM policy for Terraform operations used by the Atlantis server.
# This policy is intentionally scoped to networking and EC2 resources managed in this module,
# instead of using the broad PowerUserAccess managed policy.
resource "aws_iam_role_policy" "atlantis_terraform" {
  name = "atlantis-terraform-operations"
  role = aws_iam_role.atlantis.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["ec2:*", "vpc:*"],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "read_secrets"
  role = aws_iam_role.atlantis.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "secretsmanager:GetSecretValue",
      Resource = [
        "arn:aws:secretsmanager:us-west-2:778265708060:secret:atlantis/prod/config-k9SyAP",
        "arn:aws:secretsmanager:us-west-2:778265708060:secret:atlantis/ansible-ssh-key-btUinW"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "atlantis" {
  name = "atlantis-profile"
  role = aws_iam_role.atlantis.name

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy.atlantis_terraform,
  ]
}

#########################
# Networking
#########################

# VPC
resource "aws_vpc" "main-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "${var.project_name}"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main-vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
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

# Security Group with GitHub webhook IPs
resource "aws_security_group" "atlantis" {
  name_prefix = "${var.project_name}-sg"
  description = "Security group for Atlantis server - allows GitHub webhooks + optional IP ranges"
  vpc_id      = aws_vpc.main-vpc.id

  # GitHub webhook IPs (always allowed)
  dynamic "ingress" {
    for_each = var.github_webhook_cidr_blocks
    content {
      from_port   = var.atlantis_port
      to_port     = var.atlantis_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "GitHub webhook"
    }
  }

  # Additional allowed IPs (for your access, etc.)
  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? var.allowed_cidr_blocks : []
    content {
      from_port   = var.atlantis_port
      to_port     = var.atlantis_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Atlantis web interface (custom)"
    }
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

# Assumes you have a Hosted Zone in Route53
data "aws_route53_zone" "main" {
  name = "bytetrove.xyz."
}

#####################
## Compute 
####################

# SSH Key Pair
resource "aws_key_pair" "atlantis" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "atlantis" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.atlantis.name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.atlantis.id]
  #key_name               = var.ssh_public_key != "" ? aws_key_pair.atlantis[0].key_name : null

  # 20GB Disk for Terraform Plans
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = { Name = "atlantis-server" }
}

resource "aws_route53_record" "atlantis" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "atlantis.bytetrove.xyz"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.atlantis.public_ip]
}