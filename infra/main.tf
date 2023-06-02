# Define provider (AWS)
provider "aws" {
  region = "us-east-1" # Set your desired region
}

# Create a security group
resource "aws_security_group" "app_sg" {
  name        = "app-security-group"
  description = "Security group for the Express.js app"
  
  # Allow SSH access from anywhere
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow outbound traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "instances" {
  ami           = "ami-053b0d53c279acc90" # Set your desired AMI ID
  instance_type = "t2.micro"               # Set your desired instance type
  key_name      = "terraform"          # Set the name of your EC2 key pair
  
  vpc_security_group_ids = [aws_security_group.app_sg.id] 
  associate_public_ip_address = true
  user_data  = templatefile("user_data.tftpl", {})
  

  tags = {
    Name = "express-app-instance"
  }
}
