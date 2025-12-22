variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "atlantis"
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
  default     = "0.0104"  # Max price for t3.micro spot
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Atlantis"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this to your IP for better security
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

variable "github_user" {
  description = "GitHub username for Atlantis"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub token for Atlantis"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_webhook_secret" {
  description = "GitHub webhook secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "atlantis_version" {
  description = "Atlantis version to install"
  type        = string
  default     = "0.28.1"
}
