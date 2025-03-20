# EKS Terraform Configuration

This repository contains Terraform configurations for setting up an EKS cluster and its supporting infrastructure in AWS.

## Prerequisites

- Terraform >= 0.13
- AWS CLI
- Valid AWS credentials with appropriate permissions

## Authentication Setup

Before running Terraform, ensure AWS credentials are configured using one of these methods:

1. **AWS CLI (Recommended)**:
   ```bash
   aws configure
   ```

2. **Environment Variables**:
   ```bash
   export AWS_ACCESS_KEY_ID="your_access_key"
   export AWS_SECRET_ACCESS_KEY="your_secret_key"
   export AWS_DEFAULT_REGION="your_region"
   ```

## Directory Structure

```
eks-terraform/
├── modules/              # Reusable Terraform modules
│   └── vpc/             # VPC module
├── environments/         # Environment-specific configurations
│   └── dev/             # Development environment
└── README.md
```

## Usage

1. Navigate to the environment directory:
   ```bash
   cd environments/dev
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Nginx Deployment Guide

### High-Availability Nginx Configuration
The `nginx-test.yaml` file in `environments/dev/` contains a Kubernetes deployment for Nginx with the following features:

1. **Pod Anti-Affinity**: Ensures high availability by distributing pods across nodes
   ```yaml
   affinity:
     podAntiAffinity:
       preferredDuringSchedulingIgnoredDuringExecution:
         - weight: 100
           podAffinityTerm:
             labelSelector:
               matchExpressions:
               - key: app
                 operator: In
                 values:
                 - nginx
             topologyKey: "kubernetes.io/hostname"
   ```

2. **Resource Limits**: Optimized resource allocation
   ```yaml
   resources:
     requests:
       cpu: "100m"     # 0.1 CPU cores
       memory: "128Mi" # 128MB memory
     limits:
       cpu: "200m"     # 0.2 CPU cores
       memory: "256Mi" # 256MB memory
   ```

### Deployment Steps
1. Apply the Nginx configuration:
   ```bash
   kubectl apply -f environments/dev/nginx-test.yaml
   ```

2. Verify deployment:
   ```bash
   kubectl get pods -o wide
   ```

### Troubleshooting

1. **Pending Pods**: If pods are stuck in pending state:
   ```bash
   # Check pod details
   kubectl describe pod <pod-name>
   
   # Delete existing deployment if needed
   kubectl delete deployment nginx
   
   # Reapply configuration
   kubectl apply -f nginx-test.yaml
   ```

2. **Multiple Deployments**: If you see more pods than expected:
   ```bash
   # List all deployments
   kubectl get deployments
   
   # Clean up and restart
   kubectl delete deployment nginx
   kubectl apply -f nginx-test.yaml
   ```

### Important Notes
- The deployment uses `preferredDuringSchedulingIgnoredDuringExecution` for pod anti-affinity to ensure pods can still be scheduled even if ideal node distribution isn't possible
- Default configuration creates 2 replicas for high availability
- LoadBalancer service type is used to expose the Nginx deployment

## Variables

Customize the deployment by modifying `terraform.tfvars` in the environment directory.



## CI/CD Pipeline

### Prerequisites
- Jenkins server with following plugins:
  - Docker Pipeline
  - AWS Credentials
  - Pipeline AWS Steps
  - Kubernetes CLI

### Jenkins Credentials Setup
1. AWS Credentials (aws-credentials)
   - Kind: AWS Credentials
   - ID: aws-credentials
   - Access Key ID: Your AWS access key
   - Secret Access Key: Your AWS secret key

2. Kubernetes Config (eks-kubeconfig)
   - Kind: Secret file
   - ID: eks-kubeconfig
   - File: Your EKS cluster kubeconfig

### Pipeline Stages
1. **Checkout**: Pulls latest code from repository
2. **Run Tests**: Executes pytest in Python container
3. **Build and Push**: Creates Docker image and pushes to ECR
4. **Deploy to EKS**: Updates application in Kubernetes
   - Includes automatic rollback on failure

### Configuration
All configuration variables are stored in `config.env`:
- AWS settings (region, ECR repository)
- Application settings (ports, host)
- Kubernetes settings (resources, replicas)

### Manual Pipeline Execution
1. Open Jenkins dashboard
2. Navigate to pipeline job
3. Click "Build Now"

### Monitoring Deployments
```bash
# Check deployment status
kubectl get deployments

# View deployment history
kubectl rollout history deployment/flask-app

# Check pod logs
kubectl logs -l app=flask-app
```
.
