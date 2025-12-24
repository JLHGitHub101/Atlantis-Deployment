#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Atlantis Day 0 Bootstrap Deployment${NC}"
echo "===================================="
echo ""

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}Warning: terraform.tfvars not found${NC}"
    echo "Please create terraform.tfvars from example.tfvars"
    echo ""
    echo "Quick start:"
    echo "  cp example.tfvars terraform.tfvars"
    echo "  # Edit terraform.tfvars with your values"
    echo ""
    exit 1
fi

# Check for required variables in terraform.tfvars
if ! grep -q "github_user" terraform.tfvars || ! grep -q "github_token" terraform.tfvars; then
    echo -e "${YELLOW}Warning: GitHub credentials not configured${NC}"
    echo "Please ensure github_user and github_token are set in terraform.tfvars"
    echo ""
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    echo "Please install Terraform from: https://www.terraform.io/downloads"
    exit 1
fi

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo -e "${GREEN}Initializing Terraform...${NC}"
    terraform init
    echo ""
fi

# Show what will be deployed
echo -e "${GREEN}Planning deployment...${NC}"
terraform plan
echo ""

# Ask for confirmation
read -p "Do you want to proceed with deployment? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Deploy
echo -e "${GREEN}Deploying infrastructure...${NC}"
terraform apply -auto-approve

echo ""
echo -e "${GREEN}Deployment complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Get the Atlantis URL:"
echo "   terraform output atlantis_url"
echo ""
echo "2. Configure GitHub webhook:"
echo "   - Go to your repository settings"
echo "   - Navigate to Webhooks → Add webhook"
echo "   - Set Payload URL to: http://<instance-ip>:4141/events"
echo "   - Set Content type to: application/json"
echo "   - Set Secret to your github_webhook_secret"
echo "   - Select: Pull requests, Issue comments, Pushes"
echo ""
echo "3. Test Atlantis by creating a PR with Terraform changes"
