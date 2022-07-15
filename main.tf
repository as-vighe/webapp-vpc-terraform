
resource "aws_vpc" "Webapp-vpc" {
  cidr_block = "10.10.0.0/16"
}

resource "aws_subnet" "subnet-1a" {
  vpc_id     = aws_vpc.Webapp-vpc.id
  cidr_block = "${var.subnet-1a-cidr_block}"

  tags = {
    Name = "Subnet-1a-webapp"
  }
  availability_zone       = "${var.subnet-1a}"
  map_public_ip_on_launch = "true"
}

resource "aws_subnet" "subnet-1b" {
  vpc_id     = aws_vpc.Webapp-vpc.id
  cidr_block = "10.10.2.0/24"

  tags = {
    Name = "Subnet-1b-webapp"
  }
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = "true"
}

resource "aws_subnet" "subnet-1c" {
  vpc_id     = aws_vpc.Webapp-vpc.id
  cidr_block = "10.10.3.0/24"

  tags = {
    Name = "Subnet-1c-webapp"
  }
  availability_zone = "ap-south-1c"
}

resource "aws_instance" "webapp-1a" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  tags = {
    Name = "webapp-1a"
  }
  subnet_id              = aws_subnet.subnet-1a.id
  vpc_security_group_ids = [aws_security_group.allow_port80.id]
  key_name               = "${var.key_name}"
}

resource "aws_instance" "webapp-1b" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  tags = {
    Name = "webapp-1b"
  }
  subnet_id              = aws_subnet.subnet-1b.id
  vpc_security_group_ids = [aws_security_group.allow_port80.id]
  key_name               = "${var.key_name}"
}

variable "desired_machine_count" {
  type    = string
  default = 1
}

resource "aws_instance" "webapp-1b-1" {
  count         = "${var.desired_machine_count}"
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  tags = {
    Name = "webapp-1b-1"
  }
  subnet_id              = aws_subnet.subnet-1b.id
  vpc_security_group_ids = [aws_security_group.allow_port80.id]
  key_name               = "${var.key_name}"
}

resource "aws_security_group" "allow_port80" {
  name        = "allow_port_80"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.Webapp-vpc.id

  ingress {
    description      = "allow inbound web traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "allow SSH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_internet_gateway" "webapp-IG" {
  vpc_id = aws_vpc.Webapp-vpc.id

  tags = {
    Name = "webapp-IG"
  }
}

resource "aws_route_table" "Public_RT" {
  vpc_id = aws_vpc.Webapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp-IG.id
  }

  tags = {
    Name = "Public_RT"
  }

}

resource "aws_route_table_association" "RT-asso-1a" {
  subnet_id      = aws_subnet.subnet-1a.id
  route_table_id = aws_route_table.Public_RT.id
}

resource "aws_route_table_association" "RT-asso-1b" {
  subnet_id      = aws_subnet.subnet-1b.id
  route_table_id = aws_route_table.Public_RT.id
}

resource "aws_lb_target_group" "target_group_webapp" {
  name     = "target-group-webapp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Webapp-vpc.id
}

#Create target group
resource "aws_lb_target_group_attachment" "target_group_webapp-1-attachement" {
  target_group_arn = aws_lb_target_group.target_group_webapp.arn
  target_id        = aws_instance.webapp-1a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "target_group_webapp-2-attachement" {
  target_group_arn = aws_lb_target_group.target_group_webapp.arn
  target_id        = aws_instance.webapp-1b.id
  port             = 80
}

#resource "aws_lb_target_group_attachment" "target_group_webapp-3-attachement" {
#  target_group_arn = aws_lb_target_group.target_group_webapp.arn
#  target_id        = aws_instance.webapp-1b-1.id
#  port             = 80
#}

resource "aws_lb_target_group_attachment" "target_group_webapp-4-attachement" {
  count            = length(aws_instance.webapp-1b-1)
  target_group_arn = aws_lb_target_group.target_group_webapp.arn
  target_id        = aws_instance.webapp-1b-1[count.index].id
  port             = 80
}


#This security group is for LB
resource "aws_security_group" "allow_port80_LB" {
  name        = "allow_port_80_LB"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.Webapp-vpc.id

  ingress {
    description      = "allow inbound web traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

# # Application Load Balnancer
# resource "aws_lb" "webapp-LB" {
#   name               = "webapp-lb-tf"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.allow_port80_LB.id]
#   subnets            = [aws_subnet.subnet-1a.id, aws_subnet.subnet-1b.id]

#   tags = {
#     Environment = "production"
#     Name        = "Webapp"
#   }
# }

# # Load Balancer Listener
# resource "aws_lb_listener" "webapp_listener" {
#   load_balancer_arn = aws_lb.webapp-LB.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.target_group_webapp.arn
#   }
# }

# Classic load balancer

resource "aws_elb" "webapp-ELB" {
  name               = "webapp-lb-tf"
  # internal           = false
  # load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_port80_LB.id]
  subnets            = [aws_subnet.subnet-1a.id,aws_subnet.subnet-1b.id]
  

  tags = {
    Environment = "production"
    Name = "Webapp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }

}

# Launch Configuration
resource "aws_launch_configuration" "web" {
  name_prefix = "web-"

  image_id = "${var.ami}" 
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"

  security_groups = [ aws_security_group.allow_port80.id ]
  associate_public_ip_address = true


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web-AS" {
  name = "aws-auto"
  # availability_zones = ["ap-south-1a","ap-south-1b"]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2

  health_check_type = "ELB"

  load_balancers = [aws_elb.webapp-ELB.id]
  launch_configuration = aws_launch_configuration.web.id
  vpc_zone_identifier = [aws_subnet.subnet-1a.id,aws_subnet.subnet-1b.id]

}


