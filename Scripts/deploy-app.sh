#!/bin/bash
set -e

echo "[+] Deploying app to Kubernetes..."

ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@13.203.215.239 << 'EOF'

echo "[+] Waiting for Kubernetes API server to be ready..."
until kubectl get nodes &> /dev/null; do
  echo "  ...API server not ready yet"
  sleep 5
done

echo "[+] Waiting for node to be Ready..."
kubectl wait --for=condition=Ready node --all --timeout=120s

echo "[+] Applying app manifest..."
kubectl apply -f /home/ubuntu/todo-app.yaml

echo "[+] Done deploying!"
EOF
