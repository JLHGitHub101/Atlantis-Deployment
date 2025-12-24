variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "atlantis-deployment"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for cost optimization"
  type        = string
  default     = "t3.micro"
}

variable "use_spot_instance" {
  description = "Use spot instance for maximum cost savings"
  type        = bool
  default     = true
}

variable "spot_price" {
  description = "Maximum spot price (empty for on-demand price)"
  type        = string
  default     = "0.0104" # Max price for t3.micro spot
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Atlantis UI (GitHub webhook IPs always allowed on port 4141)"
  type        = list(string)
  default     = []
}

variable "github_webhook_cidr_blocks" {
  description = "GitHub webhook IP ranges (auto-populated from GitHub API)"
  type        = list(string)
  default = [
    "140.82.112.0/20",
    "143.55.64.0/20",
    "185.199.108.0/22",
    "192.30.252.0/22",
    "20.201.28.151/32",
    "20.205.243.166/32",
    "20.87.225.0/24",
    "20.248.137.48/32",
    "20.207.73.82/32",
    "20.200.245.247/32",
    "20.201.31.182/32",
    "54.185.161.84/32",
    "54.187.174.169/32",
    "54.187.205.235/32",
    "54.187.216.72/32"
  ]
}

variable "atlantis_port" {
  description = "Port on which Atlantis will run"
  type        = number
  default     = 4141
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  default     = ""
}

variable "ansible_private_key_secret_arn" {
  type        = string
  default     = ""
  description = "ARN of Secrets Manager secret containing the private key JSON { \"private_key\": \"...\" }"
}

variable "atlantis_version" {
  description = "Atlantis version to install"
  type        = string
  default     = ""
}
