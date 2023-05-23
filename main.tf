provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "example_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "Example VPC"
  }
}

resource "aws_subnet" "subnets" {
  count = length(var.subnet_cidr_blocks)

  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = var.subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]

  tags = {
    Name = "Subnet ${count.index + 1}"
  }
}

resource "aws_instance" "instances" {
  count         = length(aws_subnet.subnets)
  ami           = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.example_sg.id]  # Add this line to associate the security group

  tags = {
    Name = "Instance ${count.index + 1}"
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "example-asg"
  max_size             = 10
  min_size             = 2
  desired_capacity     = 5
  vpc_zone_identifier  = [aws_subnet.subnets[0].id]  # Replace with the desired subnet ID
  launch_configuration = aws_launch_configuration.example_lc.name
}

resource "aws_launch_configuration" "example_lc" {
  name                 = "example-lc"
  image_id             = "ami-007855ac798b5175e"  # Replace with your desired AMI
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.example_sg.id]  # Replace with your security group ID(s)
  associate_public_ip_address = true  # Add this line if you want to associate a public IP with instances

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "example_sg" {
  name        = "example-sg"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

