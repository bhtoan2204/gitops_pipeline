output "domain_name" {
  description = "Registered domain name"
  value       = var.domain_name
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.primary.zone_id
}

output "name_servers" {
  description = "Route53 hosted zone name servers"
  value       = aws_route53_zone.primary.name_servers
}
