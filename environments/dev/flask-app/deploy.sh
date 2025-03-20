#!/bin/bash

###############################################################################
# Flask App Deployment Script
###############################################################################
# Automates the deployment of Flask app to EKS cluster
#
# Prerequisites:
#   - AWS CLI configured with proper credentials
#   - kubectl configured with EKS cluster access
#   - config.env file with required variables
#   - Docker image already built and pushed to ECR (via build-and-push.sh)
#
# Usage:
#   ./deploy.sh
#
# Required config.env variables:
#   - AWS_REGION: AWS region (e.g., us-east-2)
#   - ECR_REPO_NAME: ECR repository name
#   - FLASK_PORT: Flask app port
#   - K8S_APP_NAME: Kubernetes app name
#   - K8S_REPLICAS: Number of pod replicas
#   - K8S_SERVICE_PORT: Service port
#   - K8S_CPU_REQUEST/LIMIT: CPU resources
#   - K8S_MEMORY_REQUEST/LIMIT: Memory resources
#   - K8S_PROBE_INITIAL_DELAY: Health check initial delay
#   - K8S_PROBE_PERIOD: Health check period
###############################################################################

# Exit on any error
set -e

# Function to verify AWS and kubectl configuration
verify_prerequisites() {
    echo "Verifying prerequisites..."
    
    # Check AWS CLI configuration
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo "AWS CLI not configured properly"
        echo "Run 'aws configure' to set up AWS credentials"
        exit 1
    fi
}

    # Check kubectl configuration
    if ! kubectl cluster-info >/dev/null 2>&1; then
        echo "kubectl not configured properly"
        echo "Run 'aws eks update-kubeconfig --region <region> --name <cluster-name>'"
        exit 1
    fi


# Function to load and validate configuration
load_configuration() {
    if [ ! -f "config.env" ]; then
        echo "config.env file not found!"
        echo "Create config.env file with required variables"
        exit 1
    fi

    source config.env

    # List of required variables
    local required_vars=(
        "AWS_REGION"
        "ECR_REPO_NAME"
        "FLASK_PORT"
        "K8S_APP_NAME"
        "K8S_REPLICAS"
        "K8S_SERVICE_PORT"
        "K8S_CPU_REQUEST"
        "K8S_CPU_LIMIT"
        "K8S_MEMORY_REQUEST"
        "K8S_MEMORY_LIMIT"
        "K8S_PROBE_INITIAL_DELAY"
        "K8S_PROBE_PERIOD"
    )

    # Validate all required variables
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "Required variable $var is not set in config.env"
            exit 1
        fi
    done
}

# Main deployment process
main() {
    # Verify prerequisites
    verify_prerequisites

    # Load configuration
    load_configuration

    # Get AWS account ID
    echo "Getting AWS account ID..."
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

    # Export variables for template substitution
    export AWS_ACCOUNT_ID AWS_REGION ECR_REPO_NAME
    export FLASK_PORT K8S_APP_NAME K8S_REPLICAS K8S_SERVICE_PORT
    export K8S_CPU_REQUEST K8S_CPU_LIMIT K8S_MEMORY_REQUEST K8S_MEMORY_LIMIT
    export K8S_PROBE_INITIAL_DELAY K8S_PROBE_PERIOD

    # Generate deployment file
    echo "Generating Kubernetes deployment file..."
    envsubst < k8s-deployment.template.yaml > k8s-deployment.yaml

    # Deploy to Kubernetes
    echo "Deploying to Kubernetes..."
    kubectl apply -f k8s-deployment.yaml

    # Wait for deployment
    echo "Waiting for deployment to complete..."
    kubectl rollout status deployment/${K8S_APP_NAME}

    # Get service URL
    echo "Getting service URL..."
    export SERVICE_IP=$(kubectl get svc ${K8S_APP_NAME} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

    # Display results
    echo "Application deployed successfully!"
    echo "Service URL: http://${SERVICE_IP}:${K8S_SERVICE_PORT}"
    echo "Health check URL: http://${SERVICE_IP}:${K8S_SERVICE_PORT}/health"
}

# Execute main function
main
