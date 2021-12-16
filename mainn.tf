# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/24"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-terraform"
  }
}

# Create Internet Gateway and Attach it to Demo VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "IGW-terraform"
  }
}

# Create Public Subnet
resource "aws_subnet" "public-subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/26"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet1"
  }
}

resource "aws_subnet" "public-subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.64/26"
  availability_zone       = "ap-south-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet2"
  }
}

# Create Route Table and Add Public Route
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}



# Associate Public Subnet to Public Route Table
resource "aws_route_table_association" "public-subnet1-route-table-association" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-subnet2-route-table-association" {
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.public-route-table.id
}

# Create Eip or Public IP
resource "aws_eip" "eip" {
  vpc = true
  depends_on = [
    aws_route_table_association.public-subnet1-route-table-association,
  ]
}


# Create Private NAT Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public-subnet1.id

  tags = {
    Name = "Nat-GW"
  }

# dependency on the Internet Gateway that Terraform cannot
# automatically infer, so it must be declared explicitly
depends_on = [
    aws_internet_gateway.igw,
  ]
}

# Create Private Subnet
resource "aws_subnet" "private-subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.128/26"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private-Subnet1"
  }
}

resource "aws_subnet" "private-subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.192/26"
  availability_zone       = "ap-south-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private-Subnet2"
  }
}

# Create Route Table and Add Private Route
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "Private-Route-Table"
  }
}


# Associate Private Subnet to Private Route Table
resource "aws_route_table_association" "private-subnet1-route-table-association" {
  subnet_id      = aws_subnet.private-subnet1.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_route_table_association" "private-subnet2-route-table-association" {
  subnet_id      = aws_subnet.private-subnet2.id
  route_table_id = aws_route_table.private-route-table.id
}


# Public Security Group Creation Ingress Security Port 22, 80 and 8000 
resource "aws_security_group" "public-security-group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "custom-port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public-Security-Group"
  }
}


# Private Security Group Creation Ingress Security Port 22, 80 and 8000 
resource "aws_security_group" "private-security-group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "custom-port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "rds-mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Private-Security-Group"
  }
}

#Create a Frontend server
resource "aws_instance" "FrontendInstance" {
     ami = "ami-037d4a1ae892df191"
     instance_type = "t2.micro"
     key_name = "frontend"
     subnet_id = aws_subnet.public-subnet1.id
     vpc_security_group_ids = [aws_security_group.public-security-group.id]
     associate_public_ip_address = true
      user_data = <<-EOF
        #!/bin/bash
        sudo apt update -y
        sudo sed -i "s/10.0.0.188/${aws_lb.private-load-balancer.dns_name}/" /etc/nginx/conf.d/chatapp.conf
        sudo systemctl stop nginx
        sudo systemctl start nginx
        EOF
     tags = {
       Name = "Frontend"
  }
}
# Creating Public Load Balancer
resource "aws_lb" "public-load-balancer" {
  name               = "public-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public-security-group.id]

  enable_deletion_protection = false

  subnet_mapping {
    subnet_id            = aws_subnet.public-subnet1.id
  }

  subnet_mapping {
    subnet_id            = aws_subnet.public-subnet2.id
  }

  tags = {
     Name     = "public-load-balancer"
  }
}

#Create a Public Listener on Port 80
resource "aws_lb_listener" "public-listener" {
  load_balancer_arn = aws_lb.public-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.public-target-group.id
  }

}


# Create Public Target Group
resource "aws_lb_target_group" "public-target-group" {
  name     = "public-target-group"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.vpc.id
}

#Create a Backend Server
resource "aws_instance" "BackendInstance" {
     ami = "ami-0a792bcf18ceb4e39"
     instance_type = "t2.micro"
     key_name = "frontend"
     subnet_id = aws_subnet.private-subnet1.id
     vpc_security_group_ids = [aws_security_group.private-security-group.id]
     associate_public_ip_address = false
     tags = {
       Name = "Backend"
  }
}

# Creating Private Load Balancer
resource "aws_lb" "private-load-balancer" {
  name               = "private-load-balancer"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.private-security-group.id]

  enable_deletion_protection = false

  subnet_mapping {
    subnet_id            = aws_subnet.private-subnet1.id
  }

  subnet_mapping {
    subnet_id            = aws_subnet.private-subnet2.id
  }

  tags = {
    Name         = "private-load-balancer"
  }
}

#Create a Private Listener on Port 8000
resource "aws_lb_listener" "private-listener" {
  load_balancer_arn = aws_lb.private-load-balancer.arn
  port              = "8000"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.private-target-group.id
  }
}


# Create Private Target Group
resource "aws_lb_target_group" "private-target-group" {
  name     = "private-target-group"
  port     = 8000
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.vpc.id
}


# Create Public Launch Configuration 
resource "aws_launch_configuration" "public-launch-configuration" {
  name = "public-launch-configuration"
  image_id = "ami-037d4a1ae892df191"
  security_groups = [aws_security_group.public-security-group.id]
  instance_type = "t2.micro"
  associate_public_ip_address = true
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo sed -i "s/10.0.0.188/${aws_lb.private-load-balancer.dns_name}/" /etc/nginx/conf.d/chatapp.conf
    sudo systemctl stop nginx
    sudo systemctl start nginx
    EOF
}

# Create Public Auto Scaling Group 
resource "aws_autoscaling_group" "public-autoscaling-group" {
  name                      = "public-autoscaling-group"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.public-launch-configuration.id
  vpc_zone_identifier       = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
  target_group_arns         = [aws_lb_target_group.public-target-group.id]
  tag {
    key                 = "Name"
    value               = "ASG-Frontend"
    propagate_at_launch = true
  }
}


# Create Private Launch Configuration 
resource "aws_launch_configuration" "private-launch-configuration" {
  name = "private-launch-configuration"
  image_id = "ami-0a792bcf18ceb4e39"
  security_groups = [aws_security_group.private-security-group.id]
  instance_type = "t2.micro"
  associate_public_ip_address = false
  
}

# Create Private Auto Scaling Group 
resource "aws_autoscaling_group" "private-autoscaling-group" {
  name                      = "private-autoscaling-group"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.private-launch-configuration.id
  vpc_zone_identifier       = [aws_subnet.private-subnet1.id, aws_subnet.private-subnet2.id]
  target_group_arns         = [aws_lb_target_group.private-target-group.id]
  tag {
    key                 = "Name"
    value               = "ASG-Backend"
    propagate_at_launch = true
  }
}