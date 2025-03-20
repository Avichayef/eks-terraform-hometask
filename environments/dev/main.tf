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
