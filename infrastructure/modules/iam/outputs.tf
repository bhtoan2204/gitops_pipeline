output "eks_control_plane_role_arn" {
  description = "ARN of the EKS control plane IAM role"
  value       = aws_iam_role.eks_control_plane.arn
}

output "eks_control_plane_role_name" {
  description = "Name of the EKS control plane IAM role"
  value       = aws_iam_role.eks_control_plane.name
}

output "eks_control_plane_instance_profile_name" {
  description = "Name of the EKS control plane instance profile"
  value       = aws_iam_instance_profile.eks_control_plane_profile.name
}

output "eks_control_plane_instance_profile_arn" {
  description = "ARN of the EKS control plane instance profile"
  value       = aws_iam_instance_profile.eks_control_plane_profile.arn
}
