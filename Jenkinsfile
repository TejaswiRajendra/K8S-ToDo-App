pipeline {
  agent any

  environment {
    TF_DIR = 'Terraform'
    K8S_MANIFEST = 'manifests/todo-app.yaml'
    INSTALL_SCRIPT = 'Scripts/install-k8s.sh'
    SSH_KEY = credentials('k8s-ec2-ssh') // Ensure this matches your Jenkins credentials ID
    EC2_USER = 'ubuntu' // Adjust if your EC2 instance uses a different default user
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
      when { branch 'master' }
      steps {
        script {
          env.INSTANCE_IP = sh(script: "cd ${env.TF_DIR} && terraform output -raw instance_ip", returnStdout: true).trim()
          if (!env.INSTANCE_IP) {
            error "Failed to retrieve EC2 IP address from Terraform output"
          }
          echo "EC2 Public IP: ${env.INSTANCE_IP}"
        }
      }
    }

    stage('Install Docker & Kubernetes on EC2') {
      steps {
        script {
          echo '[+] Waiting for EC2 to be ready...'
          sleep(time: 90, unit: 'SECONDS') // Adjust the sleep duration as needed

          echo '[+] Installing Docker & Kubernetes on EC2...'
          sshagent(credentials: [env.SSH_KEY]) {
            sh """
            ssh -o StrictHostKeyChecking=no ${env.EC2_USER}@${env.INSTANCE_IP} << 'EOF'
              set -e

              echo "[+] Installing prerequisites..."
              sudo apt-get update
              sudo apt-get install -y apt-transport-https ca-certificates curl gpg

              echo "[+] Adding Docker's official GPG key..."
              sudo install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              sudo chmod a+r /etc/apt/keyrings/docker.gpg

              echo "[+] Setting up the Docker repository..."
              echo \
                "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                \$(. /etc/os-release && echo "\$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

              echo "[+] Installing Docker..."
              sudo apt-get update
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              echo "[+] Adding Kubernetes APT repository..."
              sudo mkdir -p -m 755 /etc/apt/keyrings
              curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | \
                sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
              sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

              echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
                https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | \
                sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

              echo "[+] Installing kubeadm, kubelet, kubectl..."
              sudo apt-get update
              sudo apt-get install -y kubelet kubeadm kubectl
              sudo apt-mark hold kubelet kubeadm kubectl

              echo "[+] Installation completed."
            EOF
            """
          }
        }
      }
    }

    stage('Deploy App to K8s') {
      when { branch 'master' }
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'k8s-ec2-ssh', keyFileVariable: 'SSH_KEY')]) {
          sh '''
            chmod 600 $SSH_KEY
            echo "[+] Copying manifest to EC2..."
            scp -o StrictHostKeyChecking=no -i $SSH_KEY ${K8S_MANIFEST} ${EC2_USER}@${INSTANCE_IP}:/home/${EC2_USER}/
            echo "[+] Deploying app to Kubernetes..."
            ssh -o StrictHostKeyChecking=no -i $SSH_KEY ${EC2_USER}@${INSTANCE_IP} "
              echo 'Waiting for cluster to be ready...'
              until kubectl get nodes | grep -q Ready; do sleep 5; done
              kubectl apply -f /home/${EC2_USER}/todo-app.yaml
            "
          '''
        }
      }
    }
  }
}
