#!/bin/bash
set -e

echo "[+] Installing prerequisites..."
sudo apt-get update && sudo apt-get install -y \
    curl apt-transport-https gnupg2 software-properties-common socat conntrack

echo "[+] Installing Docker..."
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Set version (same across components)
K8S_VERSION="1.29.2-1.1"

echo "[+] Downloading Kubernetes .deb files manually (since apt repo is not supported on Ubuntu 24.04)..."

cd /tmp

curl -LO https://packages.cloud.google.com/apt/pool/kubectl_${K8S_VERSION}_amd64_0416ebd83fb57aa8854d9c49eeb15e8e2166cc77f58905e74ffab8cd2a49d0f3.deb
curl -LO https://packages.cloud.google.com/apt/pool/kubelet_${K8S_VERSION}_amd64_25988505ac14e06b5c10c9632e9c25ce6ff7dc8cf9e7ff1f499ae79a4f69f3c2.deb
curl -LO https://packages.cloud.google.com/apt/pool/kubeadm_${K8S_VERSION}_amd64_3ac915e0d4b8fe95692b486de3f325be0584d6ae2a1296e04e7bc1dc7c5c75f8.deb

echo "[+] Installing Kubernetes components from .deb files..."
sudo dpkg -i kubelet_*.deb kubectl_*.deb kubeadm_*.deb

sudo apt-mark hold kubelet kubeadm kubectl

echo "[+] Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

echo "[+] Setting up kubeconfig for user: $USER"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[+] Installing Calico CNI..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "[✔] Kubernetes installation completed."
