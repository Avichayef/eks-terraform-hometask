# Main config file
# orchestrates the creation of all required resources

# AWS Provider Configuration
provider "aws" {
  region = var.region
}

# Terraform Configuration Block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# VPC Module Configuration
module "vpc" {
  source = "../../modules/vpc"  # Verify this path exists

  cluster_name         = var.cluster_name
  environment         = var.environment
  region             = var.region
  vpc_cidr           = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  availability_zones  = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]
}

# EKS Module Configuration
module "eks" {
  source = "../../modules/eks"  # Verify this path exists

  cluster_name       = var.cluster_name
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  environment       = var.environment
}

# Kubernetes and Helm providers configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = module.eks.cluster_token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = module.eks.cluster_token
  }
}

# Monitoring Module Configuration
module "monitoring" {
  source = "../../modules/monitoring"

  cluster_name    = var.cluster_name
  environment     = var.environment
  namespace       = "monitoring"

  prometheus_retention_period = "15d"
  prometheus_storage_size    = "10Gi"
  prometheus_cpu_request     = "200m"
  prometheus_memory_request  = "512Mi"
  prometheus_cpu_limit       = "500m"
  prometheus_memory_limit    = "1Gi"

  grafana_storage_size      = "5Gi"
  grafana_admin_password    = var.grafana_admin_password

  enable_cloudwatch         = true
  cloudwatch_retention_days = 30

  # ALB ARN is now optional
  # alb_arn = module.alb.arn  # Uncomment and provide if you want ALB monitoring

  depends_on = [
    module.eks
  ]
}

# Output values
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "grafana_url" {
  value = module.monitoring.grafana_url
}

output "prometheus_url" {
  value = module.monitoring.prometheus_url
}
