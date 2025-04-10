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

mkdir -p /tmp/k8s-install
cd /tmp/k8s-install

# Fetch deb URLs from package index
curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages \
  | awk -v ver="$K8S_VERSION" '
    $1 == "Filename:" && $2 ~ ver { print $2 }
  ' > k8s-packages.txt

# Download each matching .deb file
while read -r pkg; do
  url="https://packages.cloud.google.com/apt/$pkg"
  echo "[*] Downloading $url"
  curl -LO "$url"
done < k8s-packages.txt

echo "[+] Installing Kubernetes components from .deb files..."
sudo dpkg -i *.deb

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
