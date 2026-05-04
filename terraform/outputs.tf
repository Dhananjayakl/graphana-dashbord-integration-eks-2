output "grafana_url" {
  description = "Grafana dashboard URL (single instance, all environments)"
  value       = "http://${var.grafana_ec2_host}:3000"
}

output "prometheus_endpoint" {
  description = "Prometheus endpoint for this environment (use in prod.tfvars as prometheus_dev_endpoint after dev deploy)"
  value       = module.prometheus.prometheus_endpoint
}

output "namespace" {
  description = "Kubernetes namespace for this environment"
  value       = module.k8s_workloads.namespace
}

output "environment" {
  description = "Active environment"
  value       = var.environment
}

output "node_exporter_enabled" {
  description = "Whether Node Exporter is enabled in this environment"
  value       = var.nodeExporter.enabled
}
