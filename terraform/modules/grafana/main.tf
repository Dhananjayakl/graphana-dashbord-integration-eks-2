terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
    }
  }
}

locals {
  grafana_port = 3000
  grafana_url  = "http://${var.grafana_ec2_host}:${local.grafana_port}"
}

# ── Single Grafana container on EC2 ────────────────────────────────────────
# One instance serves both dev and prod via separate datasources & folders.
resource "null_resource" "grafana_docker" {
  triggers = {
    image       = "grafana/grafana:10.4.2"
    config_hash = md5(var.grafana_admin_password)
  }

  connection {
    type        = "ssh"
    host        = var.grafana_ec2_host
    user        = var.ec2_ssh_user
    private_key = file(var.ec2_private_key_path)
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "docker pull grafana/grafana:10.4.2",
      "docker rm -f grafana 2>/dev/null || true",
      <<-EOF
        docker run -d \
          --name grafana \
          --restart unless-stopped \
          -p ${local.grafana_port}:3000 \
          -e GF_SECURITY_ADMIN_USER="${var.grafana_admin_user}" \
          -e GF_SECURITY_ADMIN_PASSWORD="${var.grafana_admin_password}" \
          -e GF_SERVER_ROOT_URL="${local.grafana_url}" \
          -e GF_ANALYTICS_REPORTING_ENABLED=false \
          -v grafana-storage:/var/lib/grafana \
          grafana/grafana:10.4.2
      EOF
      ,
      "echo 'Waiting for Grafana to be healthy (max 120s)...'",
      "timeout 120s bash -c 'until curl -sf http://localhost:${local.grafana_port}/api/health; do echo \"Waiting...\"; sleep 5; done'",
      "echo 'Grafana is up!'"
    ]
  }
}

# ── Dev Datasource (always created) ───────────────────────────────────────
resource "grafana_data_source" "prometheus_dev" {
  type = "prometheus"
  name = "Prometheus-Dev"
  uid  = "prometheus-dev"
  url  = var.prometheus_dev_endpoint

  json_data_encoded = jsonencode({
    httpMethod            = "POST"
    prometheusType        = "Prometheus"
    prometheusVersion     = "2.50.0"
    customQueryParameters = "namespace=dev"
  })

  depends_on = [null_resource.grafana_docker]
}

# ── Prod Datasource (only created once prod Prometheus is deployed) ────────
resource "grafana_data_source" "prometheus_prod" {
  count = var.prometheus_prod_endpoint != "" ? 1 : 0

  type = "prometheus"
  name = "Prometheus-Prod"
  uid  = "prometheus-prod" 
  url  = var.prometheus_prod_endpoint

  json_data_encoded = jsonencode({
    httpMethod            = "POST"
    prometheusType        = "Prometheus"
    prometheusVersion     = "2.50.0"
    customQueryParameters = "namespace=prod"
  })

  depends_on = [null_resource.grafana_docker]
}

# ── Dev Folder & Dashboards (always created) ──────────────────────────────
resource "grafana_folder" "dev" {
  title      = "Dev - Kubernetes"
  uid        = "dev-kubernetes"
  depends_on = [null_resource.grafana_docker]
}

resource "grafana_dashboard" "dev_k8s_cluster" {
  config_json = templatefile("${path.module}/dashboards/k8s-cluster.json.tpl", {
    datasource_name = "Prometheus-Dev"
    environment     = "dev"
    namespace       = "dev"
  })
  folder     = grafana_folder.dev.id
  overwrite  = true
  depends_on = [grafana_data_source.prometheus_dev]
}

resource "grafana_dashboard" "dev_k8s_namespace" {
  config_json = templatefile("${path.module}/dashboards/k8s-namespace.json.tpl", {
    datasource_name = "Prometheus-Dev"
    environment     = "dev"
    namespace       = "dev"
  })
  folder     = grafana_folder.dev.id
  overwrite  = true
  depends_on = [grafana_data_source.prometheus_dev]
}

# ── Prod Folder & Dashboards (created only when prod endpoint is available) 
resource "grafana_folder" "prod" {
  count      = var.prometheus_prod_endpoint != "" ? 1 : 0
  title      = "Prod - Kubernetes"
  depends_on = [null_resource.grafana_docker]
}

resource "grafana_dashboard" "prod_k8s_cluster" {
  count = var.prometheus_prod_endpoint != "" ? 1 : 0

  config_json = templatefile("${path.module}/dashboards/k8s-cluster.json.tpl", {
    datasource_name = "Prometheus-Prod"
    environment     = "prod"
    namespace       = "prod"
  })
  folder     = grafana_folder.prod[0].id
  overwrite  = true
  depends_on = [grafana_data_source.prometheus_prod]
}

resource "grafana_dashboard" "prod_k8s_namespace" {
  count = var.prometheus_prod_endpoint != "" ? 1 : 0

  config_json = templatefile("${path.module}/dashboards/k8s-namespace.json.tpl", {
    datasource_name = "Prometheus-Prod"
    environment     = "prod"
    namespace       = "prod"
  })
  folder     = grafana_folder.prod[0].id
  overwrite  = true
  depends_on = [grafana_data_source.prometheus_prod]
}
