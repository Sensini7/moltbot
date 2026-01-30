# Instance outputs
output "instance_id" {
  description = "EC2 instance ID"
  value       = module.moltbot.instance_id
}

output "public_ip" {
  description = "Public IP address of the MoltBot instance"
  value       = module.moltbot.public_ip
}

output "public_dns" {
  description = "Public DNS of the MoltBot instance"
  value       = module.moltbot.public_dns
}

output "private_ip" {
  description = "Private IP address of the MoltBot instance"
  value       = module.moltbot.private_ip
}

# SSH outputs
output "private_key" {
  description = "SSH private key for instance access (save to file)"
  value       = module.moltbot.private_key
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = module.moltbot.ssh_command
}

# MoltBot access outputs
output "gateway_token" {
  description = "Gateway authentication token"
  value       = module.moltbot.gateway_token
  sensitive   = true
}

output "tailscale_hostname" {
  description = "Expected Tailscale hostname for the instance"
  value       = module.moltbot.tailscale_hostname
}

output "tailscale_url" {
  description = "Tailscale HTTPS URL for accessing MoltBot"
  value       = module.moltbot.tailscale_url
}

output "tailscale_url_with_token" {
  description = "Tailscale URL with authentication token (use this to access MoltBot)"
  value       = module.moltbot.tailscale_url_with_token
  sensitive   = true
}

# Network outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.moltbot.vpc_id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = module.moltbot.subnet_id
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.moltbot.security_group_id
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = module.moltbot.ami_id
}
