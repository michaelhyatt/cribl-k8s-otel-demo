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

  # Install docker and docker-compose, create directories
  provisioner "remote-exec" {
    inline = [
      "sudo sysctl -w vm.max_map_count=262144",
      "sudo apt-get update -y",
      "sudo apt-get install -y git docker.io docker-compose-v2",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ubuntu",
    ]
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

  # Deploy everything
  provisioner "remote-exec" {
    inline = [
      "cd /home/ubuntu",
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
