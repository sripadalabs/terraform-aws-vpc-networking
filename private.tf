locals {
  private_subnet_map = { for subnet in var.private_subnets : subnet.key => subnet }
  private_subnet_egress = {
    for key, subnet in local.private_subnet_map :
    key => subnet.egress != null ? subnet.egress : (var.internet_ingress ? "public_nat" : "none")
  }
  public_nat_workload_subnet_map = {
    for key, subnet in local.private_subnet_map : key => subnet
    if local.private_subnet_egress[key] == "public_nat"
  }
  public_nat_azs = toset([
    for subnet in values(local.public_nat_workload_subnet_map) : subnet.az
  ])
  public_subnet_by_az = {
    for subnet in var.public_subnets : subnet.az => subnet
  }
  public_nat_public_subnet_by_az = {
    for az in local.public_nat_azs : az => local.public_subnet_by_az[az]
  }
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
  for_each = local.public_nat_public_subnet_by_az

  tags = {
    Name = "nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each = local.public_nat_public_subnet_by_az

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value.key].id

  tags = {
    Name = "nat-gateway-${each.key}"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = local.private_subnet_map

  vpc_id = var.vpc_id

  tags = {
    Name = "private-route-table-${each.key}"
  }
}

resource "aws_route" "public_nat" {
  for_each = local.public_nat_workload_subnet_map

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value.az].id
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnet_map

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
