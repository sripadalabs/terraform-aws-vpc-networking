locals {
  private_subnet_map = { for subnet in var.private_subnets : subnet.key => subnet }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnet_map

  vpc_id                              = var.vpc_id
  cidr_block                          = each.value.cidr
  availability_zone                   = each.value.az
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
