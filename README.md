# Atlantis Day 0 Bootstrap Deployment

This is a Day 0 Bootstrap deployment of [Atlantis](https://www.runatlantis.io/) built using Terraform and configured with Ansible. The infrastructure is deployed on AWS with maximum cost optimization.

## Overview

This repository provides a complete Infrastructure as Code (IaC) solution to deploy Atlantis, a tool for automating Terraform via pull requests. The deployment is optimized for cost savings using AWS spot instances and minimal resource requirements.

The deployment uses **Ubuntu 22.04 LTS** as the base operating system for reliability and long-term support.

## Cost Optimization Features

- **Spot Instances**: Uses AWS Spot Instances by default for up to 70% cost savings
- **Right-sized Instance**: Defaults to `t3.micro` instance type (~$0.0104/hour on-demand, ~$0.003/hour spot)
- **Minimal Infrastructure**: Single instance deployment with essential networking only
- **Auto-scaling Ready**: Can be extended to use auto-scaling groups for production workloads

## Architecture

```
├── VPC (10.0.0.0/16)
│   ├── Public Subnet (10.0.1.0/24)
│   │   └── EC2 Instance (t3.micro spot)
│   │       └── Atlantis Server (port 4141)
│   ├── Internet Gateway
│   └── Security Group (SSH + Atlantis port)
```

## Prerequisites

1. **AWS Account** with appropriate credentials configured
2. **Terraform** >= 1.0 installed
3. **Ansible** (optional, for alternative configuration method)
4. **GitHub Account** with a personal access token
5. **SSH Key Pair** (optional, for EC2 access)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/JLHGitHub101/Atlantis-Deployment.git
cd Atlantis-Deployment
```

### 2. Configure Variables

Copy the example variables file and edit it with your values:

```bash
cp example.tfvars terraform.tfvars
```

Edit `terraform.tfvars` and fill in required values:

```hcl
# GitHub Configuration (required)
github_user           = "your-github-username"
github_token          = "ghp_your_github_token"
github_webhook_secret = "your-webhook-secret"

# Optional: Add your SSH public key for EC2 access
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
```

**Generate a webhook secret:**
```bash
openssl rand -hex 20
```

**Create a GitHub Personal Access Token:**
1. Go to GitHub Settings → Developer Settings → Personal Access Tokens
2. Generate new token with `repo` scope
3. Copy the token (starts with `ghp_`)

### 3. Deploy Infrastructure

**Option A: Using the deploy script (recommended)**
```bash
./deploy.sh
```

**Option B: Manual deployment**
```bash
terraform init
terraform plan
terraform apply
```

### 4. Access Atlantis

After deployment, Terraform will output the Atlantis URL:

```bash
terraform output atlantis_url
```

Visit the URL in your browser to see the Atlantis web interface.

### 5. Configure GitHub Webhook

1. Go to your GitHub repository settings
2. Navigate to Webhooks → Add webhook
3. Set Payload URL to: `http://<instance-ip>:4141/events`
4. Set Content type to: `application/json`
5. Set Secret to your `github_webhook_secret`
6. Select events: Pull requests, Issue comments, Pushes
7. Save the webhook

## Configuration Options

### Terraform Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | `us-east-1` | No |
| `instance_type` | EC2 instance type | `t3.micro` | No |
| `use_spot_instance` | Use spot instance for cost savings | `true` | No |
| `spot_price` | Maximum spot instance price | `0.0104` | No |
| `github_user` | GitHub username | - | Yes |
| `github_token` | GitHub personal access token | - | Yes |
| `github_webhook_secret` | Webhook secret | - | Yes |
| `ssh_public_key` | SSH public key for EC2 access | - | No |
| `allowed_cidr_blocks` | CIDR blocks allowed to access Atlantis | `["0.0.0.0/0"]` | No |

### Cost Comparison

| Configuration | Hourly Cost | Monthly Cost (730 hrs) |
|---------------|-------------|------------------------|
| t3.micro spot | ~$0.003 | ~$2.19 |
| t3.micro on-demand | ~$0.0104 | ~$7.59 |
| t3.small spot | ~$0.007 | ~$5.11 |
| t3.small on-demand | ~$0.0208 | ~$15.18 |

*Prices are approximate and vary by region*

## Alternative: Ansible Configuration

If you prefer to configure an existing instance with Ansible:

```bash
cd ansible

# Update inventory.ini with your instance IP
vim inventory.ini

# Export GitHub credentials
export GITHUB_USER="your-github-username"
export GITHUB_TOKEN="ghp_your_token"
export GITHUB_WEBHOOK_SECRET="your-secret"

# Run the playbook
ansible-playbook -i inventory.ini playbook.yml
```

## Outputs

After successful deployment, Terraform provides the following outputs:

- `atlantis_url`: URL to access Atlantis web interface
- `instance_public_ip`: Public IP address of the EC2 instance
- `instance_id`: EC2 instance ID
- `ssh_command`: SSH command to connect to the instance
- `cost_optimization`: Details about cost optimization settings

## Managing Atlantis

### SSH into Instance

```bash
ssh -i /path/to/key.pem ubuntu@<instance-ip>
```

### Check Service Status

```bash
sudo systemctl status atlantis
```

### View Logs

```bash
sudo journalctl -u atlantis -f
```

### Restart Service

```bash
sudo systemctl restart atlantis
```

## Security Considerations

1. **Restrict Access**: Update `allowed_cidr_blocks` to your IP address instead of `0.0.0.0/0`
   ```hcl
   allowed_cidr_blocks = ["YOUR_IP/32"]  # Replace with your IP
   ```

2. **Secure Credentials**: Use AWS Secrets Manager or Parameter Store for sensitive data in production

3. **Update Regularly**: Keep Atlantis version updated for security patches

4. **Use HTTPS**: This deployment uses HTTP by default. For production:
   - Add an Application Load Balancer with SSL/TLS certificate
   - Or use Let's Encrypt with certbot on the instance
   - Update webhook URL to use HTTPS

5. **Repo Allowlist**: Configure specific repositories instead of using `'*'` wildcard
   ```bash
   --repo-allowlist='github.com/yourorg/*'
   ```

6. **Multi-AZ**: For production, consider deploying across multiple availability zones

## Cleanup

To destroy all resources:

**Option A: Using the destroy script**
```bash
./destroy.sh
```

**Option B: Manual destruction**
```bash
terraform destroy
```

## Troubleshooting

### Spot Instance Not Available

If spot instances are unavailable in your region, set:
```hcl
use_spot_instance = false
```

### Atlantis Not Starting

1. Check logs: `sudo journalctl -u atlantis -f`
2. Verify GitHub credentials are correct
3. Ensure webhook secret matches GitHub configuration

### Cannot Access Web Interface

1. Check security group rules
2. Verify instance is running: `terraform output instance_id`
3. Ensure port 4141 is accessible from your IP

## Next Steps

1. Configure [atlantis.yaml](https://www.runatlantis.io/docs/repo-level-atlantis-yaml.html) in your repositories
2. Set up [custom workflows](https://www.runatlantis.io/docs/custom-workflows.html)
3. Configure [server-side repo config](https://www.runatlantis.io/docs/server-side-repo-config.html)
4. Add SSL/TLS with Application Load Balancer
5. Implement monitoring and alerting

## Resources

- [Atlantis Documentation](https://www.runatlantis.io/)
- [Atlantis GitHub Repository](https://github.com/runatlantis/atlantis)
- [AWS Spot Instances](https://aws.amazon.com/ec2/spot/)
- [Terraform Documentation](https://www.terraform.io/docs)

## License

This project is provided as-is for Day 0 bootstrap purposes.

## Contributing

Contributions are welcome! Please submit pull requests or open issues for improvements.
