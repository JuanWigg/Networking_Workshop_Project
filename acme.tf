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

    tags = {
        Name = "ACMEPublica"
    }
}

resource "aws_subnet" "ACMEEmpleados" {
    vpc_id = aws_vpc.vpc-acme.id
    cidr_block = "172.16.4.0/22"

    tags = {
        Name = "ACMEEmpleados"
    }
}

resource "aws_subnet" "ACMEServicios" {
    vpc_id = aws_vpc.vpc-acme.id
    cidr_block = "172.16.1.0/24"

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
      gateway_id = 
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
        gateway_id = 
    }
}

resource "aws_route_table" "tablaEmpleadosAcme" {
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = 
    }
    route{
        cidr_block = "10.0.0.0/16"
        gateway_id = 
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

resource "aws_route_table_association" "tablaEmpleadosAsociation" {
  subnet_id      = aws_subnet.ACMEPublica.id
  route_table_id = aws_route_table.tablaEmpleadosAcme.id
}




# Instancias
## Proxy Reverso
# Interfaz de red
resource "aws_network_interface" "primaria_proxyrev"{
  subnet_id   = aws_subnet.ACMEPublica.id
  private_ips = ["172.16.0.5"]
  device_index = 0
  tags = {
    Name = "publica_network_interface"
  }
}

resource "aws_network_interface" "secundaria_proxyrev"{
  subnet_id   = aws_subnet.ACMEPublica.id
  private_ips = ["172.16.1.5"]
  device_index = 1
  tags = {
    Name = "servicios_network_interface"
  }
}

resource "aws_instance" "ProxyREV"{
    ami = "ami-0ed9277fb7eb570c9"
    instance_type = "t2.micro"




}






### Security Groups
## Proxy Reverso
