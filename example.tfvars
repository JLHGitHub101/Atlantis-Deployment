# Example Terraform Variables
# Copy this file to terraform.tfvars and fill in your values

# AWS Configuration
aws_region  = "us-east-1"
environment = "dev"

# Instance Configuration
instance_type       = "t3.micro"  # Cost-optimized: ~$0.0104/hour on-demand
use_spot_instance   = true        # Use spot instance for maximum savings (~70% discount)
spot_price          = "0.0104"    # Maximum spot price

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# Security Configuration
# IMPORTANT: Replace with your IP address for better security
allowed_cidr_blocks = ["0.0.0.0/0"]  # Change to ["YOUR_IP/32"] for production

# SSH Configuration (optional - for manual access)
# Generate SSH key pair: ssh-keygen -t rsa -b 4096 -f ~/.ssh/atlantis-key
# ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... your-key-here"

# GitHub Configuration (required for Atlantis to work)
# Create a GitHub personal access token with repo scope
github_user           = "your-github-username"
github_token          = "ghp_your_github_personal_access_token"
github_webhook_secret = "your-random-webhook-secret"  # Generate with: openssl rand -hex 20

# Atlantis Configuration
atlantis_version = "0.28.1"
atlantis_port    = 4141
