#!/bin/bash
set -e

# Clone app repo
git clone https://github.com/TejaswiRajendra/K8S-ToDo-App.git
cd K8S-ToDo-App

# Apply Kubernetes manifest
kubectl apply -f todo-app.yaml
