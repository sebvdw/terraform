provider "aws" {
  region = var.aws_region
}
resource "aws_vpc" "example_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "Example VPC"
  }
}
resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id

  tags = {
    Name = "Example IGW"
  }
}
resource "aws_route_table" "example_route_table" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_igw.id
  }

  tags = {
    Name = "Example Route Table"
  }
}
resource "aws_subnet" "subnets" {
  count                 = length(var.subnet_cidr_blocks)
  vpc_id                = aws_vpc.example_vpc.id
  cidr_block            = var.subnet_cidr_blocks[count.index]
  availability_zone     = var.availability_zones[count.index]

  tags = {
    Name = "Subnet ${count.index + 1}"
  }
}
resource "aws_route_table_association" "example_route_table_association" {
  count            = length(aws_subnet.subnets)
  subnet_id        = aws_subnet.subnets[count.index].id
  route_table_id   = aws_route_table.example_route_table.id
}
resource "aws_instance" "instances" {
  count         = length(aws_subnet.subnets)
  ami           = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.example_sg.id]  # Add this line to associate the security group
  associate_public_ip_address = true
  tags = {
    Name = "Instance ${count.index + 1}"
  }
}
resource "aws_autoscaling_group" "asg" {
  name                 = "example-asg"
  max_size             = 4
  min_size             = 2
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.subnets[0].id]  # Replace with the desired subnet ID
  launch_configuration = aws_launch_configuration.example_lc.name
}

## PLEEASE CHECK THE BLOW METRIC ALARM AND SCALING POLICY <3333
resource "aws_autoscaling_policy" "example_policy" {
  name                   = "terraform-test-policy"
  scaling_adjustment     = 4
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "example_alarm" {
  alarm_name          = "terraform-test-example-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.example_policy.arn]
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
### Load Balancer ADDED HERE
resource "aws_lb" "example_lb" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example_sg.id]
  subnets            = aws_subnet.subnets[*].id
}

resource "aws_lb_target_group" "example_target_group" {
  name     = "example-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.example_vpc.id
}

resource "aws_lb_listener" "example_listener" {
  load_balancer_arn = aws_lb.example_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.example_target_group.arn
    type             = "forward"
  }
}