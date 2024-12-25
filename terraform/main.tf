# Update it to the correct region
variable "region" {
  description = "AWS region to deploy the box in"
  default = "us-west-2"
}

variable "pemfile" {
  description = "Full path to the .pem file with the keypair to connect to AWS instances"
}

variable "keyname" {
  description = "The name of the keypair to use to create AWS instance with"
}

variable "ami" {
  description = "Ubintu 24 Server AMI to use"
}

variable "server_name" {
  description = "Give it a name we can recognise in AWS EC2 console"
}

variable "cribl_edge_leader_url" {
  description = "The leader URL for the Cribl Edge"
}

variable "cribl_edge_token" {
  description = "The token for the Cribl Edge"
}

variable "cribl_edge_version" {
  description = "The version of the Cribl Edge"
}

variable "cribl_edge_fleet" {
  description = "The fleet name for the Cribl Edge"
}

variable "cribl_stream_leader_url" {
  description = "The leader URL for the Cribl Stream"
}

variable "cribl_stream_token" {
  description = "The token for the Cribl Stream"
}

variable "cribl_stream_version" {
  description = "The version of the Cribl Stream"
}

variable "cribl_stream_worker_group" {
  description = "The worker group for the Cribl Stream"
}


provider "aws" {
  region = var.region
}

resource "aws_security_group" "otel-demo-security-group" {
  name_prefix = "otel-demo-"
  description = "Allow inbound traffic"

  # Kibana
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Otel demo app frontend 
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress all is open
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "otel-demo-security-group"
  }
}

data "aws_ip_ranges" "ec2_instance_connect" {
  regions  = ["${var.region}"]  
  services = ["ec2_instance_connect"]
}

resource "aws_instance" "otel-demo-server" {
  ami           = var.ami 
  instance_type = "c5.2xlarge"
  key_name = var.keyname
  vpc_security_group_ids = [aws_security_group.otel-demo-security-group.id]

  root_block_device {
    volume_size = 50 
    volume_type = "gp2"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.pemfile)
    host        = self.public_ip
  }

  # Copy the cribl dir
  provisioner "file" {
    source      = "${path.module}/../cribl"
    destination = "/home/ubuntu"
  }

  # Copy the elastic dir
  provisioner "file" {
    source      = "${path.module}/../elastic"
    destination = "/home/ubuntu"
  }

  # Copy the kind dir
  provisioner "file" {
    source      = "${path.module}/../kind"
    destination = "/home/ubuntu"
  }

  # Copy the otel-demo dir
  provisioner "file" {
    source      = "${path.module}/../otel-demo"
    destination = "/home/ubuntu"
  }

  # Install everything
  provisioner "remote-exec" {
    inline = [
        "sudo sysctl -w vm.max_map_count=262144",
        "sudo apt-get update -y",
        "sudo apt-get install -y git docker.io docker-compose-v2",
        "sudo systemctl start docker",
        "sudo systemctl enable docker",
        "sudo usermod -aG docker ubuntu",
        "sudo apt install snapd -y",
        "sudo snap install kubectl --classic",
        "sudo snap install helm --classic",
        "[ $(uname -m) = x86_64 ] && curl -Lo ./kind.exec https://kind.sigs.k8s.io/dl/v0.26.0/kind-linux-amd64",
        "[ $(uname -m) = aarch64 ] && curl -Lo ./kind.exec https://kind.sigs.k8s.io/dl/v0.26.0/kind-linux-arm64",
        "chmod +x ./kind.exec",
        "sudo mv ./kind.exec /usr/local/bin/kind",
        "helm repo add cribl https://criblio.github.io/helm-charts/",
        "sudo snap install k9s",
        "sudo ln -s /snap/k9s/current/bin/k9s /usr/local/bin",
    ]
  }

  # Deploy everything
  provisioner "remote-exec" {
    inline = [
        "echo 'Creating the kind cluster'",
        "kind create cluster --config kind/kind-ec2-cluster-config.yaml --name cluster --quiet",
        "kubectl cluster-info --context kind-cluster",
        "kubectl create -f https://download.elastic.co/downloads/eck/2.15.0/crds.yaml",
        "kubectl apply -f https://download.elastic.co/downloads/eck/2.15.0/operator.yaml",

        <<EOT
            helm install --repo "https://criblio.github.io/helm-charts/" \
                --version "^${var.cribl_edge_version}" --create-namespace -n "cribl" \
                --set "cribl.leader=tls://${var.cribl_edge_token}@${var.cribl_edge_leader_url}?group=${var.cribl_edge_fleet}" \
                --set "env.CRIBL_K8S_TLS_REJECT_UNAUTHORIZED=0" \
                --values cribl/edge/values.yaml \
                "cribl-edge" edge
        EOT
        ,
        "kubectl apply -n elastic-system -f elastic/license.yaml",
        "kubectl create ns elastic",
        "kubectl apply -n elastic -f elastic/elastic.yaml",

        "kubectl wait deployment/kibana-kb -n elastic --for=create --timeout=10m",
        "kubectl wait deployment/kibana-kb -n elastic --for=condition=Available=True --timeout=10m",

        "kubectl apply -n elastic -f elastic/add_dashboard.yml",

        "kubectl wait deployment/elastic-agent-agent -n elastic --for=create --timeout=10m",
        "kubectl wait deployment/elastic-agent-agent -n elastic --for=condition=Available=True --timeout=10m",
        "kubectl wait deployment/fleet-server-agent -n elastic --for=create --timeout=10m",
        "kubectl wait deployment/fleet-server-agent -n elastic --for=condition=Available=True --timeout=10m",   
        "kubectl wait svc/apm -n elastic --for=condition=Available=True --timeout=10m", 
        "kubectl wait svc/prometheus -n elastic --for=condition=Available=True --timeout=10m", 

        <<EOT
            kubectl patch deployment kibana-kb -n elastic --type='json' -p \
            '[{"op": "add", "path": "/spec/template/spec/containers/0/ports/0/hostPort", "value": 5601}]'
        EOT
        ,
        <<EOT
            helm install --repo "https://criblio.github.io/helm-charts/" --version "^${var.cribl_stream_version}" --create-namespace -n "cribl" \
                --set "config.host=${var.cribl_stream_leader_url}" \
                --set "config.token=${var.cribl_stream_token}" \
                --set "config.group=${var.cribl_stream_worker_group}" \
                --set "config.tlsLeader.enable=true"  \
                --set "env.CRIBL_K8S_TLS_REJECT_UNAUTHORIZED=0" \
                --set "env.CRIBL_MAX_WORKERS=4" \
                --values cribl/stream/values.yaml \
                "cribl-worker" logstream-workergroup
        EOT
        ,
        "kubectl wait deployment/cribl-worker-logstream-workergroup -n cribl --for=create --timeout=600s",
        "kubectl wait deployment/cribl-worker-logstream-workergroup -n cribl --for=condition=Available=True --timeout=600s",

        <<EOT
            kubectl patch deployment cribl-worker-logstream-workergroup -n cribl --type='json' -p \
            '[{"op": "add", "path": "/spec/template/spec/containers/0/ports/0/hostPort", "value": 10200}]'
        EOT
        ,     

        "kubectl apply --namespace otel-demo -f otel-demo/opentelemetry-demo.yaml",

        "kubectl wait deployment/opentelemetry-demo-frontendproxy -n otel-demo --for=create --timeout=10m",
        "kubectl wait deployment/opentelemetry-demo-frontendproxy -n otel-demo --for=condition=Available=True --timeout=10m",

        <<EOT
            kubectl patch deployment opentelemetry-demo-frontendproxy -n otel-demo --type='json' -p \
            '[{"op": "add", "path": "/spec/template/spec/containers/0/ports/0/hostPort", "value": 8080}]'
        EOT
        ,
    ]
  }


  tags = {
    Name = var.server_name
  }
}

# Change the security group to allow SSH connections only from EC2 SSH console
resource "null_resource" "disable_ssh" {

  provisioner "local-exec" {
    command = "aws ec2 revoke-security-group-ingress --region ${var.region} --group-id ${aws_security_group.otel-demo-security-group.id} --protocol tcp --port 22 --cidr 0.0.0.0/0"
  }

  provisioner "local-exec" {
    command = "aws ec2 authorize-security-group-ingress --region ${var.region} --group-id ${aws_security_group.otel-demo-security-group.id} --protocol tcp --port 22 --cidr ${data.aws_ip_ranges.ec2_instance_connect.cidr_blocks[0]}"
  }

  triggers = {
    instance_id = aws_instance.otel-demo-server.id
  }

  depends_on = [aws_instance.otel-demo-server]
}

output "instance_public_hostname" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.otel-demo-server.public_dns
}
