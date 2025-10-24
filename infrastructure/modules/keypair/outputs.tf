output "key_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.eks_control_plane.key_name
}

output "key_pair_id" {
  description = "ID of the AWS key pair"
  value       = aws_key_pair.eks_control_plane.key_pair_id
}
