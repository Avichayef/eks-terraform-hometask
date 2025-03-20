# Flask Application Deployment

This directory contains a Flask application deployment for the Kubernetes DevOps Challenge.

## Directory Structure
```
flask-app/
├── app.py              # Flask application
├── requirements.txt    # Python dependencies
├── Dockerfile         # Container configuration
├── build-and-push.sh  # ECR build and push script
└── k8s-deployment.yaml # Kubernetes deployment configuration
```

## Prerequisites
- AWS CLI configured with proper credentials
- kubectl installed and configured
- Docker installed
- Access to an EKS cluster

## Deployment Steps

1. Configure kubectl with your EKS cluster:
   ```bash
   aws eks update-kubeconfig --region us-east-2 --name <cluster-name> --api-version client.authentication.k8s.io/v1beta1
   ```

2. Build and push the Docker image to ECR:
   ```bash
   chmod +x build-and-push.sh
   ./build-and-push.sh
   ```

3. Deploy to Kubernetes:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

4. Verify the deployment:
   ```bash
   kubectl get pods
   kubectl get services
   ```

5. Test the application:
   ```bash
   # Get the LoadBalancer URL
   export SERVICE_IP=$(kubectl get svc flask-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
   
   # Test endpoints
   curl http://$SERVICE_IP/
   curl http://$SERVICE_IP/health
   ```

## Configuration Details

### Resource Limits
- CPU Request: 100m (0.1 CPU cores)
- CPU Limit: 200m (0.2 CPU cores)
- Memory Request: 128Mi
- Memory Limit: 256Mi

### Health Checks
- Liveness Probe: /health endpoint
- Readiness Probe: /health endpoint
- Initial Delay: 5 seconds
- Period: 10 seconds

### High Availability
- Deployment runs 2 replicas
- LoadBalancer service type for external access

### Dependencies
- Flask 2.0.1
- Werkzeug 2.0.3 (Required for compatibility)

## Maintenance Commands

### Monitoring
```bash
# Watch pods status
kubectl get pods -w

# Check logs
kubectl logs -f -l app=flask-app

# Check deployment details
kubectl describe deployment flask-app
```

### Scaling
```bash
# Scale replicas
kubectl scale deployment flask-app --replicas=3
```

### Updates
```bash
# After making changes to app.py:
./build-and-push.sh
kubectl rollout restart deployment flask-app
```

### Cleanup
```bash
# Delete the deployment and service
kubectl delete -f k8s-deployment.yaml
```
