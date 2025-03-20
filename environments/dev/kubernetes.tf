# Kubernetes and Helm provider configuration
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

# Data sources for EKS cluster
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

# Monitoring Module Configuration
module "monitoring" {
  source = "../../modules/monitoring"

  cluster_name              = var.cluster_name
  environment              = var.environment
  namespace                = "monitoring"

  prometheus_retention_period = "15d"
  prometheus_storage_size    = "10Gi"
  prometheus_cpu_request     = "200m"
  prometheus_memory_request  = "512Mi"
  prometheus_cpu_limit       = "500m"
  prometheus_memory_limit    = "1Gi"

  grafana_admin_password    = var.grafana_admin_password
  grafana_storage_size      = "5Gi"

  enable_cloudwatch         = true
  cloudwatch_retention_days = 30

  depends_on = [
    module.eks
  ]
}

output "grafana_url" {
  value = module.monitoring.grafana_url
}

output "prometheus_url" {
  value = module.monitoring.prometheus_url
}