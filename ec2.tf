resource "aws_security_group" "allow_traffic" { # allow_ssh / ssh
  name        = "allow_traffic"
  description = "Allow  inbound traffic"
  vpc_id      = aws_vpc.siec.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["89.64.32.166/32"] #przy wpisanym moim ip mogę połączyć się ssh, przy innym nie

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"] # czy rzeczywiście potrzebujemy wypuścić ruch po ipv6?
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_traffic" # allow-traffic -> nazwa w AWSie
  }
}


resource "aws_network_interface" "nic-prod" { # just "prod"
  subnet_id       = aws_subnet.subnet-prod.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_traffic.id]

}


resource "aws_eip" "one" { # nomenklatura -> this
  vpc                       = true
  network_interface         = aws_network_interface.nic-prod.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.InternetGateway]
}


resource "aws_instance" "zad1" {
  ami               = "ami-0d75513e7706cf2d9"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-1a"
  key_name          = "main"

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
