#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Destroying Atlantis infrastructure...${NC}"
echo "===================================="
echo ""

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo -e "${RED}Error: Terraform not initialized${NC}"
    echo "Run 'terraform init' first"
    exit 1
fi

# Show what will be destroyed
echo -e "${GREEN}Planning destruction...${NC}"
terraform plan -destroy
echo ""

# Ask for confirmation
read -p "Are you sure you want to destroy all resources? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Destruction cancelled"
    exit 0
fi

# Destroy
echo -e "${YELLOW}Destroying infrastructure...${NC}"
terraform destroy -auto-approve

echo ""
echo -e "${GREEN}All resources have been destroyed${NC}"
