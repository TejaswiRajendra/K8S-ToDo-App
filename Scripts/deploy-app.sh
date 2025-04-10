#!/bin/bash
set -e

echo "[+] Cloning app repo..."
git clone https://github.com/TejaswiRajendra/K8S-ToDo-App.git
cd K8S-ToDo-App

echo "[+] Waiting for Kubernetes API to be ready..."
until kubectl get nodes &> /dev/null; do
  sleep 5
  echo "  ...still waiting for API server"
done

echo "[+] Waiting for node to be Ready..."
kubectl wait --for=condition=Ready node --all --timeout=120s

echo "[+] Waiting for Calico pods to be ready..."
kubectl wait --for=condition=Ready pods -n kube-system -l k8s-app=calico-node --timeout=120s

echo "[+] Deploying app to Kubernetes..."
kubectl apply -f todo-app.yaml

echo "[+] Deployment complete!"

