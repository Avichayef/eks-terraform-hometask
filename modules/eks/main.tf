# Main EKS cluster and nodes config

# EKS Cluster
# Creates the control plane and associated resources
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.27"  # Kubernetes version

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id]
    subnet_ids             = var.private_subnet_ids
    endpoint_private_access = true  # Allow private endpoint access
    endpoint_public_access  = true  # Allow public endpoint access
  }

  # Ensure IAM role policies are attached before creating the cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# EKS Node Group
# Creates a managed node group for running workloads
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  # Node group scaling configuration
  scaling_config {
    desired_size = 2  # Number of nodes to run
    max_size     = 3 # Max nodes
    min_size     = 2  # Min nodes
  }

  # Instance type for worker nodes
  instance_types = ["t3.small"]  

  # Ensure IAM role policies attached before creating the node group
  depends_on = [
    aws_iam_role_policy_attachment.node_group_policies
  ]
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.name
}
