#!/bin/bash
set -e

echo "Deploying core components..."

kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/rabbitmq-deployment.yaml
kubectl apply -f k8s/zot-deployment.yaml

echo "Starting Kaniko build jobs..."

kubectl apply -f k8s/kaniko-build-chat.yaml
kubectl apply -f k8s/kaniko-build-notification.yaml
kubectl apply -f k8s/kaniko-build-logging.yaml

echo "Waiting for Kaniko jobs to complete..."
kubectl wait --for=condition=complete --timeout=300s job/build-chat-service
kubectl wait --for=condition=complete --timeout=300s job/build-notification-service
kubectl wait --for=condition=complete --timeout=300s job/build-logging-service

echo "All Kaniko jobs completed. Waiting for images to propagate..."
sleep 10

# Get the ClusterIP for the Zot registry service
registry_ip=$(kubectl get svc zot-service -o jsonpath='{.spec.clusterIP}')
registry_endpoint="http://${registry_ip}:80"

echo "Checking Zot registry at ${registry_endpoint} for pushed images..."
for repo in chat-service notification-service logging-service; do
  echo "Checking repository: ${repo}"
  result=$(curl -s ${registry_endpoint}/v2/_catalog | grep ${repo} || true)
  if [[ -z "${result}" ]]; then
    echo "Error: Repository '${repo}' not found in Zot registry!"
    exit 1
  else
    echo "Repository '${repo}' found."
  fi
done

echo "All images are available in the Zot registry."
echo "Deploying application services..."

kubectl apply -f k8s/chat-deployment.yaml
kubectl apply -f k8s/notification-deployment.yaml
kubectl apply -f k8s/logging-deployment.yaml

echo "Deployment completed successfully."