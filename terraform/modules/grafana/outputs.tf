output "grafana_url" {
  description = "Grafana dashboard URL (single instance for all environments)"
  value       = "http://${var.grafana_ec2_host}:3000"
}
