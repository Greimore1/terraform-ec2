# Configure AWS provider
provider "aws" {
  region = "eu-east-2"  # Chosen as it's the geographically closest region to me
}

# Get the default VPC data
data "aws_vpc" "default" {
  default = true
}

# Creates a security group
resource "aws_security_group" "web" {
  name        = "web-server-sg"
  description = "Security group for web server"
  vpc_id      = data.aws_vpc.default.id

  # Allows incoming HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

# Uses the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Creates the actual EC2 instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><body><h1>Hello, World!</h1></body></html>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "hello-world-web-server"
  }
}

# Outputs the public IP address
output "public_ip" {
  value = aws_instance.web.public_ip
}
