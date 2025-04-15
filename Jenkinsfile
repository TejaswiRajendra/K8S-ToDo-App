pipeline {
  agent any

  environment {
    TF_DIR = 'Terraform'
    K8S_MANIFEST = 'manifests/todo-app.yaml'
    EC2_USER = 'ubuntu'
  }

  stages {
    stage('Terraform Init') {
      when { branch 'master' }
      steps {
        withCredentials([
          string(credentialsId: 'aws_access_key', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          dir("${env.TF_DIR}") {
            sh 'terraform init'
          }
        }
      }
    }

    stage('Terraform Plan') {
      when { branch 'master' }
      steps {
        withCredentials([
          string(credentialsId: 'aws_access_key', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          dir("${env.TF_DIR}") {
            sh 'terraform plan'
          }
        }
      }
    }

    stage('Terraform Apply') {
      when { branch 'master' }
      steps {
        withCredentials([
          string(credentialsId: 'aws_access_key', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws_secret_key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          dir("${env.TF_DIR}") {
            sh 'terraform apply -auto-approve'
          }
        }
      }
    }

    stage('Fetch EC2 IP') {
      steps {
        script {
          env.INSTANCE_IP = sh(script: "cd ${env.TF_DIR} && terraform output -raw instance_ip", returnStdout: true).trim()
          if (!env.INSTANCE_IP) {
            error "Failed to retrieve EC2 IP address"
          }
          echo "EC2 Public IP: ${env.INSTANCE_IP}"
        }
      }
    }

    stage('Install Docker & Kubernetes on EC2 (Ubuntu 22.04)') {
      steps {
        script {
          echo '[+] Waiting for EC2 to be ready...'
          sleep(time: 90, unit: 'SECONDS')

          sshagent(credentials: ['k8s-ec2-ssh']) {
            sh """
              ssh -o StrictHostKeyChecking=no ${EC2_USER}@${env.INSTANCE_IP} << 'EOF'
                set -e
                echo "[+] Updating system..."
                sudo apt-get update -y

                echo "[+] Installing Docker..."
                sudo apt-get install -y ca-certificates curl gnupg lsb-release
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                echo \
                  "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
                  https://download.docker.com/linux/ubuntu \
                  \$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update -y
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io

                echo "[+] Enabling Docker service..."
                sudo systemctl enable docker
                sudo systemctl start docker

                echo "[+] Installing Kubernetes..."
                sudo mkdir -p -m 755 /etc/apt/keyrings
                curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | \
                  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
                echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | \
                  sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y kubelet kubeadm kubectl
                sudo apt-mark hold kubelet kubeadm kubectl

                echo "[+] Initializing Kubernetes..."
                sudo kubeadm init --pod-network-cidr=192.168.0.0/16

                echo "[+] Setting up kubeconfig..."
                mkdir -p \$HOME/.kube
                sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
                sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config

                echo "[+] Applying Calico networking..."
                kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

                echo "[+] Allowing master node to schedule pods..."
                kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

                echo "[+] Setup complete."
              EOF
            """
          }
        }
      }
    }

    stage('Deploy App to K8s') {
      steps {
        sshagent(credentials: ['k8s-ec2-ssh']) {
          sh """
            echo "[+] Copying manifest to EC2..."
            scp -o StrictHostKeyChecking=no ${K8S_MANIFEST} ${EC2_USER}@${env.INSTANCE_IP}:/home/${EC2_USER}/

            echo "[+] Deploying to Kubernetes..."
            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${env.INSTANCE_IP} << 'EOF'
              until kubectl get nodes | grep -q ' Ready'; do
                echo "Waiting for node to be ready..."
                sleep 5
              done
              kubectl apply -f /home/${EC2_USER}/todo-app.yaml
            EOF
          """
        }
      }
    }
  }
}
