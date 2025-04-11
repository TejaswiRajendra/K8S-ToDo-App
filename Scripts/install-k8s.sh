#!/bin/bash

set -e

echo "[+] Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y apt-transport-https curl

echo "[+] Adding Kubernetes APT repository..."
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg

sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'

echo "[+] Installing kubeadm, kubelet, kubectl..."
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[+] Kubernetes installation completed."
