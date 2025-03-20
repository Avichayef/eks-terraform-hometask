# variables for the EKS module

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the EKS cluster will be created"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs where EKS nodes will be launched"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod, staging)"
}
