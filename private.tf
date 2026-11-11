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
  public_nat_public_subnet_key_by_az = {
    for az in local.public_nat_azs : az => try([
      for subnet in var.public_subnets : subnet.key if subnet.az == az
    ][0], null)
  }
  public_nat_gateway_azs = {
    for az, subnet_key in local.public_nat_public_subnet_key_by_az : az => subnet_key
    if var.internet_ingress && subnet_key != null
  }
  public_nat_workload_routes = {
    for key, subnet in local.public_nat_workload_subnet_map : key => subnet
    if var.internet_ingress && lookup(local.public_nat_public_subnet_key_by_az, subnet.az, null) != null
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

  lifecycle {
    precondition {
      condition     = contains(["none", "public_nat", "private_only"], local.private_subnet_egress[each.key])
      error_message = "Private subnet egress must be one of: none, public_nat, or private_only."
    }
  }
}

resource "aws_eip" "nat" {
  for_each = local.public_nat_gateway_azs

  tags = {
    Name = "nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each = local.public_nat_gateway_azs

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value].id

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
  for_each = local.public_nat_workload_routes

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value.az].id
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnet_map

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id

  lifecycle {
    precondition {
      condition     = local.private_subnet_egress[each.key] != "public_nat" || var.internet_ingress
      error_message = "Private subnets with egress = \"public_nat\" require internet_ingress = true."
    }
    precondition {
      condition     = local.private_subnet_egress[each.key] != "public_nat" || lookup(local.public_nat_public_subnet_key_by_az, each.value.az, null) != null
      error_message = "Private subnets with egress = \"public_nat\" require a public subnet in the same AZ."
    }
  }
}
