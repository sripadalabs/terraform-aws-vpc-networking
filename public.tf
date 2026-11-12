locals {
  public_subnet_map      = { for subnet in var.public_subnets : subnet.key => subnet }
  public_route_table_azs = var.internet_ingress ? toset([for subnet in var.public_subnets : subnet.az]) : toset([])
}

resource "aws_subnet" "public" {
  for_each = local.public_subnet_map

  vpc_id                              = var.vpc_id
  cidr_block                          = each.value.cidr
  availability_zone_id                = each.value.az
  private_dns_hostname_type_on_launch = "ip-name"
  map_public_ip_on_launch             = false # default is false

  tags = merge(
    {
      Name       = "Public Subnet ${upper(split("-", each.value.az)[1])}"
      SubnetType = each.value.subnet_type
      SubnetKey  = each.key
    },
    each.value.tags
  )
}

resource "aws_internet_gateway" "this" {
  count  = var.internet_ingress ? 1 : 0
  vpc_id = var.vpc_id

  tags = {
    Name = "igw-${var.vpc_id}"
  }
}

resource "aws_route_table" "public" {
  for_each = local.public_subnet_map

  vpc_id = var.vpc_id

  tags = {
    Name = "Public Route Table ${upper(split("-", each.value.az)[1])}"
  }
}

resource "aws_route" "public_internet" {
  for_each = local.public_subnet_map

  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  for_each = var.internet_ingress ? local.public_subnet_map : {}

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

resource "aws_eip" "nat" {
  for_each = {for item in var.public_subnets : item.az => item if var.internet_ingress}

  tags = {
    Name = "NAT EIP ${each.key}"
  }
}

resource "aws_nat_gateway" "public_nat" {
  for_each = {for item in var.public_subnets : item.az => item if var.internet_ingress}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value.key].id

  tags = {
    Name = "NAT Gateway ${upper(split("-", each.value.az)[1])}"
  }

  depends_on = [aws_internet_gateway.this]
}