#!/bin/bash
set -e

echo "[+] Installing prerequisites..."
sudo apt-get update && sudo apt-get install -y \
    curl wget apt-transport-https ca-certificates gnupg2 software-properties-common

echo "[+] Installing Docker..."
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Downloading Kubernetes .deb files manually (since apt repo is not supported on Ubuntu 24.04)..."
cd /tmp
KUBE_VERSION=1.29.2-1.1

wget https://packages.cloud.google.com/apt/pool/kubeadm_${KUBE_VERSION}_amd64_3ac915e0d4b8fe95692b486de3f325be0584d6ae2a1296e04e7bc1dc7c5c75f8.deb -O kubeadm.deb
wget https://packages.cloud.google.com/apt/pool/kubectl_${KUBE_VERSION}_amd64_9cb540ae38465fe601dded21514e01e33cc4d3d9286bcd4bb5937c5fdbe59aa3.deb -O kubectl.deb
wget https://packages.cloud.google.com/apt/pool/kubelet_${KUBE_VERSION}_amd64_180a5ebcb479962f4d1cb4d2b4012957d8dd033190113219c8dfcc34d87f3ea6.deb -O kubelet.deb

echo "[+] Installing Kubernetes components..."
sudo dpkg -i kubelet.deb kubectl.deb kubeadm.deb
sudo apt-mark hold kubelet kubeadm kubectl

echo "[+] Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

echo "[+] Setting up kubectl config for user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[+] Installing Calico CNI..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
