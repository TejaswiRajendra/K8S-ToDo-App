#!/bin/bash
set -e

echo "[+] Installing dependencies..."
sudo apt-get update && sudo apt-get install -y \
  apt-transport-https ca-certificates curl gpg software-properties-common

echo "[+] Installing Docker..."
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Adding Kubernetes GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-archive-keyring.gpg >/dev/null

echo "[+] Adding Kubernetes apt repository..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] \
https://apt.kubernetes.io/ kubernetes-xenial main" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "[+] Installing kubeadm, kubelet, kubectl..."
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[+] Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

echo "[+] Configuring kubectl for current user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[+] Installing Calico network plugin..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
