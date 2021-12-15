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