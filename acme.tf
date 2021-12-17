#Defino el proveedor de Cloud
provider "aws" {
    region = "us-east-1"
    shared_credentials_file = "/Users/Piche/.aws/credentials"
}


#Defino primero la VPC 
resource "aws_vpc" "vpc-acme"{
    cidr_block = "172.16.0.0/16"
    tags = {
        Name = "ACME_Prod_VPC"
    }
}



#Defino las subnets para la VPC
resource "aws_subnet" "ACMEPublica" {
    vpc_id = aws_vpc.vpc-acme.id
    cidr_block = "172.16.0.0/28"
    availability_zone = "us-east-1a"
    tags = {
        Name = "ACMEPublica"
    }
}

resource "aws_subnet" "ACMEInterna" {
    vpc_id = aws_vpc.vpc-acme.id
    cidr_block = "172.16.4.0/22"
    availability_zone = "us-east-1a"
    tags = {
        Name = "ACMEInterna"
    }
}

resource "aws_subnet" "ACMEServicios" {
    vpc_id = aws_vpc.vpc-acme.id
    cidr_block = "172.16.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "ACMEServicios"
    }
}


# Internet Gateway
resource "aws_internet_gateway" "gw_acme" {
  vpc_id = aws_vpc.vpc-acme.id

  tags = {
    Name = "IGWAcme"
  }
}


#Tablas de ruteo
## Tabla default
resource "aws_default_route_table" "tablaMainAcme" {
  default_route_table_id = aws_vpc.vpc-acme.default_route_table_id

    route{
      cidr_block = "10.0.0.0/16"
      gateway_id = aws_network_interface.multiserver_nic1
  }

  route{
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw_acme.id
  }

  tags = {
    Name = "PublicaACME"
  }
}

# Tablas
resource "aws_route_table" "tablaServiciosAcme" {
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_network_interface.proxy_rev_nic2
    }
    tags = {
    Name = "ServiciosACME"
  }
}

resource "aws_route_table" "tablaInternaAcme" {
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_network_interface.multiserver_nic2.id
    }
    route{
        cidr_block = "10.0.0.0/16"
        gateway_id = aws_network_interface.multiserver_nic2.id
    }
    tags = {
    Name = "InternaACME"
  }
}

## Asociaciones
resource "aws_route_table_association" "tablaMainAsociation" {
  subnet_id      = aws_subnet.ACMEPublica.id
  route_table_id = aws_default_route_table.tablaMainAcme.id
}

resource "aws_route_table_association" "tablaServiciosAsociation" {
  subnet_id      = aws_subnet.ACMEServicios.id
  route_table_id = aws_route_table.tablaServiciosAcme.id
}

resource "aws_route_table_association" "tablaInternaAsociation" {
  subnet_id      = aws_subnet.ACMEPublica.id
  route_table_id = aws_route_table.tablaInternaAcme.id
}

### Security Groups
## Proxy Reverso
resource "aws_security_group" "proxyrev_acme_sg"{
  name = "ProxyREV Acme"
  description = "Security Group para el Proxy Reverso de ACME"
  vpc_id = aws_vpc.vpc-acme.id

  #Reglas de entrada
  ingress {
    description = "SSH publico"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = "0.0.0.0/0"
  }
  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "ICMPv4"
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Reglas de salida
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ProxyREV Firewall"
  }

}


## Multiserver
resource "aws_security_group" "multiserver_sg"{
  #Reglas de entrada
  ingress {
    description = "SSH publico"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = "0.0.0.0/0"
  }
  ingress {
    description = "Proxy"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }
  ingress {
    description = "Asterisk"
    from_port = 10000
    to_port = 20000
    protocol = "udp"
    cidr_blocks = ["10.0.0.0/24"]
  }
  ingress {
    description = "SIP"
    from_port = 5060
    to_port = 5060
    protocol = "udp"
    cidr_blocks = ["10.0.0.0/24"]
  }
  ingress {
    description = "Wireguard"
    from_port = 51820
    to_port = 51820
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Wireguard"
    from_port = 51820
    to_port = 51820
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMPv4"
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Reglas de salida
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Multiserver Firewall"
  }
}


## Webservers
resource "aws_security_group" "prod_sg" {
  name        = "Prod Firewall"
  description = "Firewall para Webservers"
  vpc_id      = aws_vpc.vpc-acme.id


  #Reglas de entrada
  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/24"]
  }
  ingress {
    description = "ICMPv4"
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Reglas de salida
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Webservers Firewall"
  }
}


## DB
resource "aws_security_group" "db_sg" {
  name        = "DB Firewall"
  description = "Firewall para DB"
  vpc_id      = aws_vpc.vpc-acme.id


  #Reglas de entrada
  ingress {
    description      = "MYSQL Prod01"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = []
  }
  ingress {
    description      = "MYSQL Prod02"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/24"]
  }
  ingress {
    description = "ICMPv4"
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Reglas de salida
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "DB Firewall"
  }
}




### Interfaces de Red
## Proxy Reverso
resource "aws_network_interface" "proxy_rev_nic1" {
  subnet_id = aws_subnet.ACMEPublica.id
  private_ips = ["172.16.0.6"]
  security_groups = [aws_security_group.proxyrev_acme_sg.id]
}
resource "aws_network_interface" "proxy_rev_nic2" {
  subnet_id = aws_subnet.ACMEServicios.id
  private_ips = ["172.16.1.6"]
  security_groups = [aws_security_group.proxyrev_acme_sg.id]
}


## Multiserver
resource "aws_network_interface" "multiserver_nic1" {
  subnet_id = aws_subnet.ACMEPublica.id
  private_ips = ["172.16.0.7"]
  security_groups = [aws_security_group.multiserver_sg.id]
}
resource "aws_network_interface" "multiserver_nic2" {
  subnet_id = aws_subnet.ACMEInterna.id
  private_ips = ["172.16.4.7"]
  security_groups = [aws_security_group.multiserver_sg.id]
}


## Prod01
resource "aws_network_interface" "prod01_nic1" {
  subnet_id = aws_subnet.ACMEServicios.id
  private_ips = ["172.16.1.10"]
  security_groups = [aws_security_group.prod_sg.id]
}
resource "aws_network_interface" "prod01_nic2" {
  subnet_id = aws_subnet.ACMEInterna.id
  private_ips = ["172.16.4.10"]
  security_groups = [aws_security_group.prod_sg.id]
}


## Prod02
resource "aws_network_interface" "prod02_nic1" {
  subnet_id = aws_subnet.ACMEServicios.id
  private_ips = ["172.16.1.11"]
  security_groups = [aws_security_group.prod_sg.id]
}
resource "aws_network_interface" "prod02_nic2" {
  subnet_id = aws_subnet.ACMEInterna
  private_ips = ["172.16.4.11"]
  security_groups = [aws_security_group.prod_sg.id]
}


## DB01
resource "aws_network_interface" "db01_nic1" {
  subnet_id = aws_subnet.ACMEInterna.id
  private_ips = ["172.16.4.20"]
  security_groups = [aws_security_group.db_sg.id]
}



## Elastic IPs
#Proxy Reverso
resource "aws_eip" "proxyrev_eip"{
  vpc = true
  network_interface = aws_network_interface.proxy_rev_nic1.id
  associate_with_private_ip = "172.16.0.6"
  depends_on = aws_internet_gateway.gw_acme
}

#Multiserver
resource "aws_eip" "proxyrev_eip"{
  vpc = true
  network_interface = aws_network_interface.multiserver_nic1.id
  associate_with_private_ip = "172.16.0.7"
  depends_on =  aws_internet_gateway.gw_acme

}