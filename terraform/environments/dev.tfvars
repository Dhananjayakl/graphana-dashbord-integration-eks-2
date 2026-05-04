# ── dev.tfvars ─────────────────────────────────────────────────────────────
# Use with: terraform apply -var-file=environments/dev.tfvars

aws_region       = "us-east-1"
environment      = "dev"
eks_cluster_name = "demo-eks-cluster"

ec2_instance_id  = "i-0449288155e29ab2b"
ec2_ssh_user     = "ubuntu"
grafana_ec2_host = "52.20.197.39"

grafana_admin_user = "admin"
# grafana_admin_password → set via TF_VAR_grafana_admin_password env var (never commit!)

app_image      = "nginx:latest"
app_replicas   = 2
cpu_request    = "100m"
memory_request = "128Mi"

# ✅ Node Exporter ENABLED in dev (uses the object var that main.tf actually reads)
# REMOVED: node_exporter_enabled = false  ← was scalar, was ignored by main.tf
nodeExporter = {
  enabled = true
}
