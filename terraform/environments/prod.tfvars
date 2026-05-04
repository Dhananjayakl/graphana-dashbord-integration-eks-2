# ── prod.tfvars ────────────────────────────────────────────────────────────

aws_region       = "us-east-1"
environment      = "prod"
eks_cluster_name = "demo-eks-cluster"

ec2_instance_id  = "i-0449288155e29ab2b"
ec2_ssh_user     = "ubuntu"
grafana_ec2_host = "52.20.197.39"

grafana_admin_user = "admin"
# grafana_admin_password → set via TF_VAR_grafana_admin_password (never commit!)

app_image      = "nginx:latest"
app_replicas   = 3
cpu_request    = "200m"
memory_request = "256Mi"

# Node Exporter OFF in prod
nodeExporter = {
  enabled = false
}

# prometheus_dev_endpoint is NOT set here — it is injected automatically
# by the GitHub Actions pipeline reading from AWS SSM Parameter Store.
