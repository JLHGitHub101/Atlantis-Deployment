#!/bin/bash
set -e

# Update system
dnf update -y

# Install required packages
dnf install -y wget unzip git

# Create atlantis user
useradd --system --create-home --shell /bin/bash atlantis

# Download and install Atlantis
cd /tmp
wget https://github.com/runatlantis/atlantis/releases/download/v${atlantis_version}/atlantis_linux_amd64.zip
unzip atlantis_linux_amd64.zip
mv atlantis /usr/local/bin/
chmod +x /usr/local/bin/atlantis
rm atlantis_linux_amd64.zip

# Create atlantis configuration directory
mkdir -p /etc/atlantis
chown atlantis:atlantis /etc/atlantis

# Create data directory for Atlantis
mkdir -p /var/lib/atlantis
chown atlantis:atlantis /var/lib/atlantis

# Create systemd service file
cat > /etc/systemd/system/atlantis.service <<EOF
[Unit]
Description=Atlantis Terraform Pull Request Automation
After=network.target

[Service]
Type=simple
User=atlantis
Group=atlantis
WorkingDirectory=/var/lib/atlantis
ExecStart=/usr/local/bin/atlantis server \\
  --atlantis-url="http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):${atlantis_port}" \\
  --port=${atlantis_port} \\
  --gh-user="${github_user}" \\
  --gh-token="${github_token}" \\
  --gh-webhook-secret="${webhook_secret}" \\
  --data-dir=/var/lib/atlantis \\
  --repo-allowlist='*'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Atlantis service if credentials are provided
%{ if github_user != "" && github_token != "" && webhook_secret != "" ~}
systemctl daemon-reload
systemctl enable atlantis
systemctl start atlantis
%{ else ~}
echo "GitHub credentials not provided. Atlantis service created but not started."
echo "Configure credentials in /etc/systemd/system/atlantis.service and start manually with: systemctl start atlantis"
%{ endif ~}

# Create a simple landing page
cat > /tmp/setup-complete.txt <<EOF
Atlantis installation complete!
Version: ${atlantis_version}
Port: ${atlantis_port}

To start Atlantis manually (if not already running):
  sudo systemctl start atlantis

To check status:
  sudo systemctl status atlantis

To view logs:
  sudo journalctl -u atlantis -f
EOF

echo "User data script completed successfully"
