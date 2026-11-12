locals {
  private_subnet_map = { for subnet in var.private_subnets : subnet.key => subnet }  
}

resource "aws_subnet" "private" {
  for_each = local.private_subnet_map

  vpc_id                              = var.vpc_id
  cidr_block                          = each.value.cidr
  availability_zone_id                = each.value.az
  private_dns_hostname_type_on_launch = "ip-name"

  tags = merge(
    {
      Name       = "Private Subnet ${upper(split("-", each.value.az)[1])}"
      SubnetType = each.value.subnet_type
      SubnetKey  = each.key
    },
    each.value.tags
  )
}

resource "aws_route_table" "private" {
  for_each = local.private_subnet_map

  vpc_id = var.vpc_id

  tags = {
    Name = "private-route-table-${each.value.az}"
  }
}

resource "aws_route" "public_nat" {
  for_each = local.private_subnet_map

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value.az].id
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnet_map

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
