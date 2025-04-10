#!/bin/bash
set -e

echo "[+] Installing prerequisites..."
sudo apt-get update && sudo apt-get install -y \
    curl apt-transport-https gnupg2 software-properties-common

echo "[+] Installing Docker..."
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Adding Kubernetes GPG key..."
# Create keyrings dir if it doesn't exist
sudo mkdir -p /etc/apt/keyrings

# Download and save GPG key if not already present
if [ ! -f /etc/apt/keyrings/kubernetes-archive-keyring.gpg ]; then
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
else
    echo "[*] GPG key already exists, skipping."
fi

echo "[+] Adding Kubernetes apt repository..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

echo "[+] Installing Kubernetes components..."
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[+] Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

echo "[+] Setting up kubeconfig for current user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[+] Installing Calico CNI..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "[✔] Kubernetes cluster setup complete."
