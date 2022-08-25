# Wiem, że na na potrzeby ćwiczeń polski, but please continue in english
# zasoby pojawiające się tylko raz w konfiguracji najlepiej nazywać "this" - nazwa teżmoże jednozancznie wskazywać na zastosowanie, np: "ec2", "main" czy "shared_services"

resource "aws_vpc" "siec" {
  cidr_block       = "10.0.1.0/24"
  instance_tenancy = "default"

  tags = {
    # tak jak wyżej - angielski
    # to są tagi wychodzące do AWSa, często są 2 podstawowe,t.j.: Name i Owner
    # Owner = "jrybarski"
    Name = "siec" # --> "skillup-network"
  }
}


# zwłaszcza, że tu wjeżdża angielski w nomenklaturze xD
resource "aws_internet_gateway" "InternetGateway" { # inna nazwa - teraz jest masło maślane, pierwszy człon jużmówi, żeto będzie IGW --> najlepiej "this" albo cos jak "main" czy "default"
  vpc_id = aws_vpc.siec.id

  tags = {
    # konwencją jest też, żeby nazewnictwo chmurowe, czyli tagi, były rozdzielone myślnikami "-" i z małej litery
    Name = "InternetGateway" # --> "internet-gateway", a jeszcze lepiej w tym wypadku: "main-igw" albo po prostu "main"
  }
}


# same as above, masło maślane, przy tego typu po prostu będę pisał "nomenklatura" od teraz
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.siec.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.InternetGateway.id
  }

  # czy to rzeczywiście jest nam potrzebne?
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.InternetGateway.id
  }

  tags = {
    Name = "RouteTable" # nomenklatura
  }
}


resource "aws_subnet" "subnet-prod" { # subnet-prod -> prod
  vpc_id            = aws_vpc.siec.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "subnet-prod"
  }
}


resource "aws_route_table_association" "a" { # a -> prod
  subnet_id      = aws_subnet.subnet-prod.id
  route_table_id = aws_route_table.routetable.id
}

