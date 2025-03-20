#!/bin/bash

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus and Grafana
helm install prometheus prometheus-community/kube-prometheus-stack \
  -f prometheus-values.yaml \
  --namespace monitoring

# Create CloudWatch namespace and deploy agent
kubectl create namespace amazon-cloudwatch
kubectl apply -f cloudwatch-agent-config.yaml

# Deploy HPA
kubectl apply -f ../flask-app/hpa.yaml

# Install metrics server if not present
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify installations
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=300s
kubectl wait --for=condition=Ready pods --all -n amazon-cloudwatch --timeout=300s

echo "Monitoring stack deployed successfully!"
echo "Access Grafana:"
echo "kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"