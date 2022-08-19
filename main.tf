provider "aws" {
    region = "eu-west-1"
    access_key = "AKIAZJ4Y6W6NVTU6OQBB"
    secret_key = "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"
}

# 1. Create VPC 

resource "aws_vpc" "siec" {
  cidr_block       = "10.0.1.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "siec"
  }
}

# 2. Create Internet Gateway

resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.siec.id

  tags = {
    Name = "InternetGateway"
  }
}

# 3. Create custom route table

resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.siec.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.InternetGateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.InternetGateway.id
  }

  tags = {
    Name = "RouteTable"
  }
}

# 4. Create a subnet

resource "aws_subnet" "subnet-prod" {
  vpc_id     = aws_vpc.siec.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "subnet-prod"
  }
}

# 5. Assosiate subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-prod.id
  route_table_id = aws_route_table.routetable.id
}

# 6. Create Security Group to allow ports

resource "aws_security_group" "allow_traffic" {
  name        = "allow_traffic"
  description = "Allow  inbound traffic"
  vpc_id      = aws_vpc.siec.id



   ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["89.64.32.166/32"] #przy wpisanym moim ip mogę połączyć się ssh, przy innym nie
   
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_traffic"
  }
}

# 7. Create a network interface with an ip in the subnet created in step 4

resource "aws_network_interface" "nic-prod" {
  subnet_id       = aws_subnet.subnet-prod.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_traffic.id]

}

# 8. Assign an elastic ip to the network interface created in step 7\

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.nic-prod.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.InternetGateway]
}

# 9. Create a serrver with appache(Optional)

resource "aws_instance" "zad1" {
  ami           = "ami-0d75513e7706cf2d9" 
  instance_type = "t2.micro"
  availability_zone = "eu-west-1a"
  key_name = "main"

  network_interface {
     network_interface_id = aws_network_interface.nic-prod.id
    device_index         = 0
  }
user_data = <<-EOF
               #!/bin/bash
                 sudo apt update -y
                 sudo apt install apache2 -y
                 sudo systemctl start apache2
                 sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                 EOF
   tags = {
     Name = "web-server"
  }
}
