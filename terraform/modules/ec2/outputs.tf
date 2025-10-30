# EC2 Module Outputs

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.eks_control_plane.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.eks_control_plane.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.eks_control_plane.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.eks_control_plane.public_dns
}

output "instance_private_dns" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.eks_control_plane.private_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.eks_control_plane.id
}

output "ssh_connection_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ./ssh/${var.key_name}.pem ubuntu@${aws_instance.eks_control_plane.public_ip}"
}

