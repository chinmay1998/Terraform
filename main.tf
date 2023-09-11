provider "aws" {
	region = "ap-south-2"
}


resource "aws_vpc" "ck_vpc" {
	cidr_block = "10.10.0.0/16"
	tags = {
		Name = "chinmay_vpc"
	}
}

resource "aws_subnet" "sub1" {
	vpc_id = aws_vpc.ck_vpc.id
	cidr_block = "10.10.10.0/24"
	availability_zone = "ap-south-2a"
	map_public_ip_on_launch = true
	tags = {
		Name = "chinmay_subnet1"
	}
}

resource "aws_subnet" "sub2" {
	vpc_id = aws_vpc.ck_vpc.id
	cidr_block = "10.10.11.0/24"
	availability_zone = "ap-south-2b"
	map_public_ip_on_launch = true
	tags = {
		Name = "chinmay_subnet2"
	}
}

resource "aws_internet_gateway" "igw" {
	vpc_id = aws_vpc.ck_vpc.id
	tags = {
		Name = "chinmay_igw"
	}
}

resource "aws_route_table" "RT" {
	vpc_id = aws_vpc.ck_vpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.igw.id
	}
}

resource "aws_route_table_association" "rta1" {
	subnet_id = aws_subnet.sub1.id
	route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
	subnet_id = aws_subnet.sub2.id
	route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "ck_sg" {
	name = "ck"
	vpc_id = aws_vpc.ck_vpc.id
	ingress {
		description = "HTTP from vpc"
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		description = "SSH"
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	tags = {
		Name = "chinmay-sg"
	}
}

resource "aws_s3_bucket" "example" {
  bucket = "chinmay-project"
}

resource "aws_instance" "server1" {
	ami = "ami-07f701d2aadc08e67"
	instance_type = "t3.micro"
	vpc_security_group_ids = [aws_security_group.ck_sg.id]
	subnet_id = aws_subnet.sub1.id
	user_data = base64encode(file("userdata.sh"))
}

resource "aws_instance" "server2" {
        ami = "ami-07f701d2aadc08e67"
        instance_type = "t3.micro"
        vpc_security_group_ids = [aws_security_group.ck_sg.id]
        subnet_id = aws_subnet.sub2.id
        user_data = base64encode(file("userdata1.sh"))
}

#create alb

resource "aws_lb" "myalb" {
	name = "myalb"
	internal = false
	load_balancer_type = "application"
	security_groups = [aws_security_group.ck_sg.id]
	subnets = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}

resource "aws_lb_target_group" "tg" {
	name = "myTG"
	port = 80
	protocol = "HTTP"
	vpc_id = aws_vpc.ck_vpc.id

	health_check {
		path = "/"
		port = "traffic-port"
	}
}


resource "aws_lb_target_group_attachment" "attach1" {
	target_group_arn = aws_lb_target_group.tg.arn
	target_id = aws_instance.server1.id
	port = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.server2.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
	load_balancer_arn = aws_lb.myalb.arn
	port = 80
	protocol = "HTTP"
	default_action {
		target_group_arn = aws_lb_target_group.tg.arn
		type = "forward"
	}
}

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}















