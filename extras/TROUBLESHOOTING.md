# Troubleshooting Guide

Common issues and solutions for Atlantis deployment.

## Deployment Issues

### Issue: Terraform init fails

**Symptoms:**
```
Error: Failed to install provider
```

**Solutions:**
1. Check internet connectivity
2. Verify AWS credentials are configured:
   ```bash
   aws sts get-caller-identity
   ```
3. Try updating Terraform:
   ```bash
   terraform version
   ```

### Issue: Spot instance not available

**Symptoms:**
```
Error: Error launching source instance: InsufficientInstanceCapacity
```

**Solutions:**
1. Switch to on-demand instances:
   ```hcl
   use_spot_instance = false
   ```
2. Try a different instance type:
   ```hcl
   instance_type = "t3a.micro"  # AMD-based alternative
   ```
3. Try a different availability zone:
   ```hcl
   # Modify main.tf availability_zone selection
   ```

### Issue: Permission denied when creating resources

**Symptoms:**
```
Error: UnauthorizedOperation
```

**Solutions:**
1. Verify AWS credentials have sufficient permissions
2. Check IAM policy includes:
   - ec2:*
   - vpc:*
   - iam:CreateRole
   - iam:CreateInstanceProfile

## Atlantis Service Issues

### Issue: Atlantis service not starting

**Symptoms:**
```bash
systemctl status atlantis
# Shows: failed or inactive
```

**Solutions:**
1. Check logs:
   ```bash
   sudo journalctl -u atlantis -n 50 --no-pager
   ```

2. Verify GitHub credentials:
   ```bash
   # Check if credentials are set in systemd service
   sudo cat /etc/systemd/system/atlantis.service
   ```

3. Test Atlantis manually:
   ```bash
   sudo -u atlantis /usr/local/bin/atlantis server \
     --atlantis-url="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):4141" \
     --port=4141 \
     --gh-user="YOUR_USER" \
     --gh-token="YOUR_TOKEN" \
     --gh-webhook-secret="YOUR_SECRET"
   ```

### Issue: Cannot access Atlantis web interface

**Symptoms:**
- Connection timeout when accessing http://instance-ip:4141
- Browser shows "This site can't be reached"

**Solutions:**
1. Check security group allows your IP:
   ```bash
   aws ec2 describe-security-groups --group-ids $(terraform output -raw instance_id)
   ```

2. Verify instance is running:
   ```bash
   terraform output instance_public_ip
   aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)
   ```

3. Check if Atlantis is listening:
   ```bash
   ssh ubuntu@$(terraform output -raw instance_public_ip)
   sudo netstat -tlnp | grep 4141
   ```

4. Verify firewall settings:
   ```bash
   sudo iptables -L -n
   ```

### Issue: GitHub webhook not working

**Symptoms:**
- PRs don't trigger Atlantis
- Webhook shows errors in GitHub

**Solutions:**
1. Check webhook secret matches:
   ```bash
   # On EC2 instance
   sudo grep webhook /etc/systemd/system/atlantis.service
   ```

2. Verify webhook URL is correct:
   - Should be: `http://INSTANCE_IP:4141/events`
   - Not: `http://INSTANCE_IP:4141` (missing /events)

3. Check webhook deliveries in GitHub:
   - Go to repository settings → Webhooks
   - Click on webhook → Recent Deliveries
   - Check response codes and messages

4. Ensure security group allows GitHub IPs:
   ```hcl
   # Consider adding GitHub's webhook IPs
   # https://api.github.com/meta
   ```

## Connection Issues

### Issue: SSH connection refused

**Symptoms:**
```
ssh: connect to host X.X.X.X port 22: Connection refused
```

**Solutions:**
1. Verify SSH key is correct:
   ```bash
   ssh-keygen -y -f ~/.ssh/your-key.pem
   # Compare with key in terraform.tfvars
   ```

2. Check security group allows your IP:
   ```bash
   curl -s https://checkip.amazonaws.com
   # Verify this IP is in allowed_cidr_blocks
   ```

3. Verify instance is running:
   ```bash
   aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)
   ```

### Issue: Spot instance terminated unexpectedly

**Symptoms:**
- Instance shows "terminated" status
- Atlantis suddenly stops responding

**Solutions:**
1. Check spot instance interruption:
   ```bash
   aws ec2 describe-spot-instance-requests
   ```

2. Switch to on-demand:
   ```hcl
   use_spot_instance = false
   ```
   ```bash
   terraform apply
   ```

3. Use persistent spot requests (modify main.tf):
   ```hcl
   spot_instance_type = "persistent"
   ```

4. Set up CloudWatch alarm for interruption notices

## Terraform Issues

### Issue: State file locked

**Symptoms:**
```
Error: Error acquiring the state lock
```

**Solutions:**
1. Wait a few minutes for lock to release
2. If stuck, force unlock (use with caution):
   ```bash
   terraform force-unlock LOCK_ID
   ```

### Issue: Resource already exists

**Symptoms:**
```
Error: resource already exists
```

**Solutions:**
1. Import existing resource:
   ```bash
   terraform import aws_instance.atlantis_spot i-1234567890abcdef0
   ```

2. Or destroy and recreate:
   ```bash
   terraform destroy -target=aws_instance.atlantis_spot
   terraform apply
   ```

## Performance Issues

### Issue: Atlantis running slow

**Symptoms:**
- Terraform plan/apply takes very long
- High CPU usage

**Solutions:**
1. Upgrade instance type:
   ```hcl
   instance_type = "t3.small"  # Double the resources
   ```

2. Check available burst credits:
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/EC2 \
     --metric-name CPUCreditBalance \
     --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Average
   ```

3. Optimize Terraform configuration:
   - Reduce number of resources
   - Use -target for specific resources
   - Enable parallelism: `terraform apply -parallelism=2`

### Issue: Out of disk space

**Symptoms:**
```
Error: No space left on device
```

**Solutions:**
1. Clean up old Atlantis data:
   ```bash
   ssh ubuntu@$(terraform output -raw instance_public_ip)
   sudo du -sh /var/lib/atlantis/*
   sudo find /var/lib/atlantis -type d -name ".terraform" -exec rm -rf {} +
   ```

2. Increase EBS volume size (modify main.tf):
   ```hcl
   root_block_device {
     volume_size = 20  # GB
   }
   ```

## GitHub Authentication Issues

### Issue: GitHub token invalid

**Symptoms:**
```
Error: GET https://api.github.com/user: 401 Bad credentials
```

**Solutions:**
1. Generate new personal access token
2. Ensure token has `repo` scope
3. Update token in terraform.tfvars
4. Redeploy or update service:
   ```bash
   ssh ec2-user@$(terraform output -raw instance_public_ip)
   # Edit service file with new token
   sudo systemctl restart atlantis
   ```

### Issue: Webhook secret mismatch

**Symptoms:**
- Webhook shows error in GitHub
- Atlantis logs: "webhook secret mismatch"

**Solutions:**
1. Verify secrets match:
   ```bash
   # Check service configuration
   ssh ubuntu@$(terraform output -raw instance_public_ip)
   sudo grep webhook-secret /etc/systemd/system/atlantis.service
   ```

2. Update GitHub webhook with correct secret

3. Or generate new secret and update both:
   ```bash
   openssl rand -hex 20
   ```

## Networking Issues

### Issue: Cannot reach GitHub from instance

**Symptoms:**
```
Error: couldn't clone repo: remote: GitHub - a moment, I'm calculating!
```

**Solutions:**
1. Check internet connectivity:
   ```bash
   ssh ubuntu@$(terraform output -raw instance_public_ip)
   ping -c 3 github.com
   curl -I https://github.com
   ```

2. Verify route table has internet gateway:
   ```bash
   terraform state show aws_route_table.public
   ```

3. Check DNS resolution:
   ```bash
   nslookup github.com
   ```

## Logs and Debugging

### Viewing Logs

**Atlantis service logs:**
```bash
sudo journalctl -u atlantis -f
```

**System logs:**
```bash
sudo tail -f /var/log/messages
```

**User data execution logs:**
```bash
sudo cat /var/log/cloud-init-output.log
```

### Debug Mode

Enable verbose logging:
```bash
ssh ubuntu@$(terraform output -raw instance_public_ip)
sudo systemctl stop atlantis

# Run in foreground with debug logging
sudo -u atlantis /usr/local/bin/atlantis server \
  --log-level=debug \
  --atlantis-url="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):4141" \
  --port=4141 \
  --gh-user="YOUR_USER" \
  --gh-token="YOUR_TOKEN" \
  --gh-webhook-secret="YOUR_SECRET"
```

## Getting Help

If you're still stuck:

1. **Check Atlantis documentation:**
   - https://www.runatlantis.io/docs/

2. **Review GitHub issues:**
   - https://github.com/runatlantis/atlantis/issues

3. **Check AWS service health:**
   - https://status.aws.amazon.com/

4. **Verify AWS region capacity:**
   - Some regions may have limited spot capacity

5. **Enable detailed CloudWatch monitoring:**
   ```bash
   aws ec2 monitor-instances --instance-ids $(terraform output -raw instance_id)
   ```

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `InsufficientInstanceCapacity` | No spot capacity | Use on-demand or different AZ |
| `UnauthorizedOperation` | Missing IAM permissions | Add required IAM policies |
| `InvalidKeyPair.NotFound` | SSH key doesn't exist | Check ssh_public_key variable |
| `401 Bad credentials` | Invalid GitHub token | Generate new token |
| `Connection refused` | Service not running | Check systemctl status |
| `No space left on device` | Disk full | Clean up or increase EBS size |
| `Rate limit exceeded` | Too many GitHub API calls | Wait or increase rate limits |

## Prevention Tips

1. **Set up monitoring:**
   - CloudWatch alarms for CPU, disk, and network
   - SNS notifications for spot interruptions

2. **Regular backups:**
   - Snapshot EBS volume weekly
   - Export Atlantis data directory

3. **Document customizations:**
   - Keep notes on manual changes
   - Use git for configuration management

4. **Test in development:**
   - Create dev environment first
   - Test changes before production

5. **Keep up to date:**
   - Update Atlantis version regularly
   - Update Terraform providers
   - Apply AWS security patches
