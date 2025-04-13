output "hosted_zone_id" {
  description = "Hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "hosted_zone_name" {
  description = "Hosted zone name"
  value       = aws_route53_zone.main.name
}

output "nameservers" {
  description = "Nameservers for the main zone"
  value       = aws_route53_zone.main.name_servers
}
