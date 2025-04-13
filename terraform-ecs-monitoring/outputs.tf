output "prometheus_url" {
  value = "http://${aws_ecs_service.prometheus.network_configuration[0].assign_public_ip ? "PublicIP" : "PrivateIP"}:9090"
}

output "grafana_url" {
  value = "http://${aws_ecs_service.grafana.network_configuration[0].assign_public_ip ? "PublicIP" : "PrivateIP"}:3000"
}