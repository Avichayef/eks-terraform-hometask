# Main config file
# AWS Provider Configuration
provider "aws" {
  region = "us-east-2"
}

# Terraform Configuration Block
terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# VPC Module Configuration
module "vpc" {
  source = "../../modules/vpc"

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
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  environment       = var.environment
}

# Output values
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_ca_certificate" {
  value = module.eks.cluster_ca_certificate
  sensitive = true
}
