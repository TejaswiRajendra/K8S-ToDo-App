#!/bin/bash
set -e

# Clone app repo
git clone https://github.com/<your-username>/k8s-todo-app.git
cd k8s-todo-app

# Apply Kubernetes manifest
kubectl apply -f todo-app.yaml
