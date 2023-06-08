provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyVPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "PrivateSubnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "InternetGateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "PublicRouteTable"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "PrivateRouteTable"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "private_route_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "public_sg" {
  name        = "PublicSecurityGroup"
  description = "Allow SSH, HTTP, HTTPS, and ICMP traffic"

  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_sg" {
  name        = "PrivateSecurityGroup"
  description = "Allow SSH"

  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "snort_instance" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "c4.large"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  private_ip                  = "10.0.1.20"

  vpc_security_group_ids = [aws_security_group.public_sg.id]

  tags = {
    Name = "SnortInstance"
  }
  user_data = data.template_file.user_data.rendered
}

data "template_file" "user_data" {
  template = file("${path.module}/bash.sh")
}

resource "aws_instance" "test_instance" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "c4.large"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  private_ip                  = "10.0.1.21"

  vpc_security_group_ids = [aws_security_group.public_sg.id]

  tags = {
    Name = "test"
  }
}

resource "aws_ec2_traffic_mirror_filter" "my_filter" {
  description      = "My Traffic Mirror Filter"
  network_services = ["amazon-dns"]

  tags = {
    Name = "MyFilter"
  }
}

resource "aws_ec2_traffic_mirror_target" "snort_target" {
  network_interface_id = aws_instance.snort_instance.primary_network_interface_id

  tags = {
    Name = "SnortTarget"
  }
}

resource "aws_ec2_traffic_mirror_session" "my_session" {
  network_interface_id     = aws_instance.test_instance.primary_network_interface_id
  session_number           = 1
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.my_filter.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.snort_target.id

  tags = {
    Name = "MySession"
  }
}
