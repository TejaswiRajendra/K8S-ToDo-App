#!/bin/bash
set -e

echo "[+] Deploying app to Kubernetes..."

ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@13.203.215.239 << 'EOF'
echo "[+] Waiting for Kubernetes API server to be ready..."
until kubectl get nodes &> /dev/null; do
  echo "  ...waiting for kube-apiserver"
  sleep 5
done

echo "[+] Waiting for node to become Ready..."
kubectl wait --for=condition=Ready node --all --timeout=120s

echo "[+] Deploying app manifest..."
kubectl apply -f /home/ubuntu/todo-app.yaml

echo "[+] Deployment complete!"
EOF
