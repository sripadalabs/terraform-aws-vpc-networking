locals {
  public_subnet_map  = { for subnet in var.public_subnets : subnet.key => subnet }
  primary_public_key = length(var.public_subnets) > 0 ? var.public_subnets[0].key : null
}

resource "aws_subnet" "public" {
  for_each = local.public_subnet_map

  vpc_id                              = var.vpc_id
  cidr_block                          = each.value.cidr
  availability_zone                   = each.value.az
  private_dns_hostname_type_on_launch = "ip-name"
  map_public_ip_on_launch             = false # default is false

  tags = merge(
    {
      Name       = "Public subnet ${each.value.az}"
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
  count  = var.internet_ingress ? 1 : 0
  vpc_id = var.vpc_id

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route" "public_internet" {
  count = var.internet_ingress ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  for_each = var.internet_ingress ? local.public_subnet_map : {}

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[0].id
}
