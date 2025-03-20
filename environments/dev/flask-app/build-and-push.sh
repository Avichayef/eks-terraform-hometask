#!/bin/bash
# Script for build and push app to ECR
    # 1. Sets up region and ECR repo name
    # 2. Gets account ID
    # 3. Creates ECR repo
    # 4. Authenticates Docker with ECR
    # 5. Builds and tags the Docker image
    # 6. Pushes the image to ECR


# Load configuration
if [ -f "config.env" ]; then
    source config.env
else
    echo "config.env file not found!"
    exit 1
fi

# Validate required variables
required_vars=("AWS_REGION" "ECR_REPO_NAME" "FLASK_PORT")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Required variable $var is not set in config.env"
        exit 1
    fi
done

echo "Starting build and push process..."

# Get AWS account ID
echo "Getting AWS account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
    echo "Failed to get AWS account ID. Make sure AWS CLI is configured correctly."
    exit 1
fi

# Create ECR repository if it doesn't exist
echo "Checking/Creating ECR repository..."
aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${AWS_REGION} || \
    aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build the Docker image with build arguments
echo "Building Docker image..."
docker build \
    --build-arg FLASK_PORT=${FLASK_PORT} \
    -t ${ECR_REPO_NAME} .

# Tag the image
echo "Tagging Docker image..."
docker tag ${ECR_REPO_NAME}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest

# Push the image to ECR
echo "Pushing image to ECR..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest

echo "Image pushed successfully to ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest"
