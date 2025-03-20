#!/bin/bash

set -e

# Function to check if resource exists in terraform state
resource_exists() {
    terraform state list | grep -q "$1"
    return $?
}

# Function to import AWS IAM role if it exists in AWS
import_iam_role() {
    local resource_address=$1
    local role_name=$2
    
    if ! resource_exists "$resource_address"; then
        if aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
            echo "Importing IAM role: $role_name"
            terraform init
            terraform import "$resource_address" "$role_name" || true
        fi
    fi
}

# Function to import IAM role policy attachment
import_role_policy() {
    local resource_address=$1
    local role_policy=$2
    
    if ! resource_exists "$resource_address"; then
        echo "Importing IAM role policy: $role_policy"
        terraform init
        terraform import "$resource_address" "$role_policy" || true
    fi
}

# Main import process
main() {
    echo "Starting Terraform import process..."
    
    # Initialize terraform first
    terraform init
    
    # Import IAM roles
    import_iam_role "module.eks.aws_iam_role.eks_cluster" "my-eks-cluster-role"
    import_iam_role "module.eks.aws_iam_role.node_group" "my-eks-node-group-role"
    
    # Import IAM role policies
    import_role_policy "module.eks.aws_iam_role_policy_attachment.eks_cluster_policy" \
        "my-eks-cluster-role/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    
    # Node group policies
    NODE_POLICIES=(
        "AmazonEKSWorkerNodePolicy"
        "AmazonEKS_CNI_Policy"
        "AmazonEC2ContainerRegistryReadOnly"
        "CloudWatchAgentServerPolicy"
    )
    
    for policy in "${NODE_POLICIES[@]}"; do
        import_role_policy \
            "module.eks.aws_iam_role_policy_attachment.node_group_policies[\"arn:aws:iam::aws:policy/$policy\"]" \
            "my-eks-node-group-role/arn:aws:iam::aws:policy/$policy"
    done
    
    echo "Import process completed"
}

main "$@"
