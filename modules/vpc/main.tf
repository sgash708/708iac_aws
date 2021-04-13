variable "service_name" {}
variable "cidr" {}
variable "region" {}
variable "azs" {
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}
locals {
  des_cidr = "0.0.0.0/0"
}

#####################
# Common
#####################
# VPC
resource "aws_vpc" "default" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true

  tags = {
    Name = var.service_name
  }
}
# InternetGateway
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = var.service_name
  }
}

#####################
# Public Settings
#####################
resource "aws_subnet" "publics" {
  count = length(var.azs)

  vpc_id            = aws_vpc.default.id
  availability_zone = var.azs[count.index]
  cidr_block        = cidrsubnet(var.cidr, 8, count.index + 1)

  tags = {
    Name = "${var.service_name}-public-${count.index + 1}"
  }
}
# RouteTable
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.service_name}-public"
  }
}
# Route
resource "aws_route" "public" {
  # allow All
  destination_cidr_block = local.des_cidr
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.default.id
}
# Association
resource "aws_route_table_association" "publics" {
  count = length(var.azs)

  subnet_id      = element(aws_subnet.publics.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
# Elastic IP
resource "aws_eip" "nats" {
  count = length(var.azs)
  vpc   = true

  tags = {
    Name = "${var.service_name}-natgw-${count.index + 1}"
  }
}
# NAT
resource "aws_nat_gateway" "nats" {
  count = length(var.azs)

  subnet_id      = element(aws_subnet.publics.*.id, count.index)
  allocation_id  = element(aws_eip.nats.*.id, count.index)

  tags = {
    Name = "${var.service_name}-${count.index + 1}"
  }
}

#####################
# Private Settings
#####################
resource "aws_subnet" "privates" {
  count = length(var.azs)

  vpc_id            = aws_vpc.default.id
  availability_zone = var.azs[count.index]
  cidr_block        = cidrsubnet(var.cidr, 8, (count.index + 1) * 10)

  tags = {
    Name = "${var.service_name}-private-${count.index + 1}"
  }
}
# RouteTable
resource "aws_route_table" "privates" {
  count  = length(var.azs)
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.service_name}-private-${count.index + 1}"
  }
}
# Route
resource "aws_route" "privates" {
  count = length(var.azs)

  # allow All
  destination_cidr_block = local.des_cidr
  nat_gateway_id         = element(aws_nat_gateway.nats.*.id, count.index)
  route_table_id         = element(aws_route_table.privates.*.id, count.index)
}
# Association
resource "aws_route_table_association" "privates" {
  count = length(var.azs)

  route_table_id = element(aws_route_table.privates.*.id, count.index)
  subnet_id      = element(aws_subnet.privates.*.id, count.index)
}