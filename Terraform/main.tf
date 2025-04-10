provider "aws" {
  region = "ap-south-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "k8s-jenkins-key"
  public_key = file("${path.module}/keys/id_rsa.pub") # You can place this in your Jenkins workspace
}

resource "aws_security_group" "k8s_sg" {
  name_prefix = "k8s-sg"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Optional: replace with your IP CIDR for security
  }

  ingress {
    description = "K8s API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort Range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_master" {
  ami                    = "ami-0e35ddab05955cf57" # Ubuntu 22.04 LTS in ap-south-1
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.deployer.key_name
  security_groups        = [aws_security_group.k8s_sg.name]

  tags = {
    Name = "K8s-Master"
  }
}

output "instance_ip" {
  value = aws_instance.k8s_master.public_ip
}
