output "atlantis_url" {
  description = "URL to access Atlantis"
  value       = var.use_spot_instance ? "http://${aws_instance.atlantis_spot[0].public_ip}:${var.atlantis_port}" : "http://${aws_instance.atlantis_ondemand[0].public_ip}:${var.atlantis_port}"
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = var.use_spot_instance ? aws_instance.atlantis_spot[0].id : aws_instance.atlantis_ondemand[0].id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = var.use_spot_instance ? aws_instance.atlantis_spot[0].public_ip : aws_instance.atlantis_ondemand[0].public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = var.use_spot_instance ? "ssh -i /path/to/key.pem ec2-user@${aws_instance.atlantis_spot[0].public_ip}" : "ssh -i /path/to/key.pem ec2-user@${aws_instance.atlantis_ondemand[0].public_ip}"
}

output "instance_type" {
  description = "Instance type used"
  value       = var.instance_type
}

output "cost_optimization" {
  description = "Cost optimization details"
  value = {
    using_spot_instance = var.use_spot_instance
    instance_type       = var.instance_type
    max_spot_price      = var.use_spot_instance ? var.spot_price : "N/A"
  }
}
