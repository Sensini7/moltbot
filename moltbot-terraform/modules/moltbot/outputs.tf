output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.moltbot.id
}

output "public_ip" {
  description = "Public IP address of the MoltBot instance"
  value       = aws_instance.moltbot.public_ip
}

output "public_dns" {
  description = "Public DNS of the MoltBot instance"
  value       = aws_instance.moltbot.public_dns
}

output "private_ip" {
  description = "Private IP address of the MoltBot instance"
  value       = aws_instance.moltbot.private_ip
}

output "private_key" {
  description = "SSH private key for instance access"
  value       = tls_private_key.moltbot_ssh.private_key_openssh
  sensitive   = true
}

output "public_key" {
  description = "SSH public key"
  value       = tls_private_key.moltbot_ssh.public_key_openssh
}

output "gateway_token" {
  description = "Gateway authentication token"
  value       = random_id.gateway_token.hex
  sensitive   = true
}

output "tailscale_hostname" {
  description = "Expected Tailscale hostname for the instance"
  value       = "ip-${replace(aws_instance.moltbot.private_ip, ".", "-")}"
}

output "tailscale_url" {
  description = "Tailscale HTTPS URL for accessing MoltBot"
  value       = "https://ip-${replace(aws_instance.moltbot.private_ip, ".", "-")}.${var.tailnet_dns_name}/"
}

output "tailscale_url_with_token" {
  description = "Tailscale URL with authentication token"
  value       = "https://ip-${replace(aws_instance.moltbot.private_ip, ".", "-")}.${var.tailnet_dns_name}/?token=${random_id.gateway_token.hex}"
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.moltbot.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.moltbot.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.moltbot.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i moltbot-key.pem ubuntu@${aws_instance.moltbot.public_ip}"
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}
