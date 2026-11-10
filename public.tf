locals {
  public_subnet_map  = { for subnet in var.public_subnets : subnet.key => subnet }
  private_subnet_map = { for subnet in var.private_subnets : subnet.key => subnet }

  primary_public_key = length(var.public_subnets) > 0 ? var.public_subnets[0].key : null
}

data "aws_availability_zone" "public" {
  for_each = local.public_subnet_map
  name     = each.value.az
}

data "aws_availability_zone" "private" {
  for_each = local.private_subnet_map
  name     = each.value.az
}

resource "aws_subnet" "public" {
  for_each = local.public_subnet_map

  vpc_id                          = var.vpc_id
  cidr_block                      = each.value.cidr
  availability_zone               = each.value.az
  availability_zone_id            = data.aws_availability_zone.public[each.key].zone_id
  private_dns_hostname_type_on_launch = "ip-name"
  map_public_ip_on_launch         = true

  tags = merge(
    {
      Name       = "Public subnet ${each.value.az}"
      SubnetType = each.value.subnet_type
      SubnetKey  = each.key
    },
    each.value.tags
  )
}

resource "aws_subnet" "private" {
  for_each = local.private_subnet_map

  vpc_id                          = var.vpc_id
  cidr_block                      = each.value.cidr
  availability_zone               = each.value.az
  availability_zone_id            = data.aws_availability_zone.private[each.key].zone_id
  private_dns_hostname_type_on_launch = "ip-name"

  tags = merge(
    {
      Name       = "Private subnet ${each.value.az}"
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

resource "aws_eip" "nat" {
  count  = var.internet_ingress && length(var.private_subnets) > 0 ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  count = var.internet_ingress && length(var.private_subnets) > 0 && local.primary_public_key != null ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[local.primary_public_key].id

  tags = {
    Name = "nat-gateway"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = var.internet_ingress && length(var.private_subnets) > 0 ? local.private_subnet_map : {}

  vpc_id = var.vpc_id

  tags = {
    Name = "private-route-table-${each.key}"
  }
}

resource "aws_route" "private_nat" {
  for_each = var.internet_ingress && length(var.private_subnets) > 0 ? local.private_subnet_map : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  for_each = var.internet_ingress && length(var.private_subnets) > 0 ? local.private_subnet_map : {}

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
