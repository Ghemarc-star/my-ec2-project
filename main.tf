# main.tf

provider "aws" {
  region = "us-east-1"
}

# Data source para sa latest Amazon Linux 2 AMI (x86_64)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "my-web-sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "my-web-sg"
  }
}

# EC2 Instance with user_data
resource "aws_instance" "my_server" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "default-ec2"

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo '<h1>Hello from my EC2!</h1><p>This is my first Terraform project.</p>' > /var/www/html/index.html
  EOF

  tags = {
    Name = "my-web-server"
  }
}

# Outputs
output "website_url" {
  description = "URL ng web server"
  value       = "http://${aws_instance.my_server.public_dns}"
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_instance.my_server.public_ip
}