pipeline {
  agent any

  environment {
    TF_DIR = 'terraform'
    K8S_MANIFEST = 'manifests/todo-app.yaml'
    INSTALL_SCRIPT = 'scripts/install-k8s.sh'
    
  }

 stage('Terraform Init & Apply') {
    steps {
        dir("${env.TF_DIR}") {
            sh 'terraform init'
            sh 'terraform plan'
            sh 'terraform apply -auto-approve'
        }
    }
}


    stage('Terraform Plan') {
      when { branch 'master' }
      steps {
        dir("${env.TF_DIR}") {
          sh 'terraform plan'
        }
      }
    }

    stage('Terraform Apply') {
      when { branch 'master' }
      steps {
        dir("${env.TF_DIR}") {
          sh 'terraform apply -auto-approve'
        }
      }
    }

    stage('Fetch EC2 IP') {
      when { branch 'master' }
      steps {
        script {
          env.INSTANCE_IP = sh(script: "cd ${env.TF_DIR} && terraform output -raw instance_ip", returnStdout: true).trim()
          echo "EC2 Public IP: ${env.INSTANCE_IP}"
        }
      }
    }

    stage('Install Docker & K8s') {
      when { branch 'master' }
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'k8s-ec2-ssh', keyFileVariable: 'SSH_KEY')]) {
          sh '''
            chmod 600 $SSH_KEY

            echo "[+] Copying install script to EC2..."
            scp -o StrictHostKeyChecking=no -i $SSH_KEY ${INSTALL_SCRIPT} ubuntu@$INSTANCE_IP:/home/ubuntu/

            echo "[+] Running install script on EC2..."
            ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$INSTANCE_IP "bash install-k8s.sh"
          '''
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
            scp -o StrictHostKeyChecking=no -i $SSH_KEY ${K8S_MANIFEST} ubuntu@$INSTANCE_IP:/home/ubuntu/

            echo "[+] Deploying app to Kubernetes..."
            ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$INSTANCE_IP "kubectl apply -f /home/ubuntu/todo-app.yaml"
          '''
        }
      }
    }
  }
}
