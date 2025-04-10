#!/bin/bash
set -e  # Exit on any error

# Log function for better pipeline output
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [+] $1"
}

log "Installing dependencies..."
sudo apt-get update -y || { echo "Failed to update package lists"; exit 1; }
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg || { echo "Failed to install dependencies"; exit 1; }

log "Installing Docker..."
sudo apt-get install -y docker.io || { echo "Failed to install Docker"; exit 1; }
sudo systemctl enable docker || { echo "Failed to enable Docker"; exit 1; }
sudo systemctl start docker || { echo "Failed to start Docker"; exit 1; }

log "Adding Kubernetes GPG key..."
sudo mkdir -p /etc/apt/keyrings
# Use --batch to avoid TTY requirement and ensure non-interactive execution
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --batch --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || { echo "Failed to add Kubernetes GPG key"; exit 1; }

log "Adding Kubernetes apt repository..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list || { echo "Failed to add Kubernetes repository"; exit 1; }

log "Installing kubeadm, kubelet, kubectl..."
sudo apt-get update -y || { echo "Failed to update package lists"; exit 1; }
sudo apt-get install -y kubeadm=1.29.2-1.1 kubelet=1.29.2-1.1 kubectl=1.29.2-1.1 || { echo "Failed to install Kubernetes components"; exit 1; }
sudo apt-mark hold kubeadm kubelet kubectl || { echo "Failed to hold Kubernetes versions"; exit 1; }

log "Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all || { echo "Failed to initialize Kubernetes cluster"; exit 1; }

log "Setting up kubectl for ubuntu user..."
mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config || { echo "Failed to copy kubeconfig"; exit 1; }
sudo chown $(id -u):$(id -g) /home/ubuntu/.kube/config || { echo "Failed to set ownership of kubeconfig"; exit 1; }

log "Installing Flannel network..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml || { echo "Failed to apply Flannel network"; exit 1; }

log "Waiting for cluster to stabilize..."
sleep 90  # Increased from 60s to ensure stability
until kubectl get nodes | grep -q Ready; do
  echo "Waiting for node to be Ready... (sleeping 30s)"
  sleep 30
done
echo "Cluster is ready!"

log "Kubernetes setup completed successfully."