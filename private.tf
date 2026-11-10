locals {
  private_subnet_map    = { for subnet in var.private_subnets : subnet.key => subnet }
  private_subnet_egress = {
    for key, subnet in local.private_subnet_map :
    key => subnet.egress != null ? subnet.egress : (var.internet_ingress ? "public_nat" : "none")
  }
  public_nat_subnet_map = {
    for key, subnet in local.private_subnet_map : key => subnet
    if local.private_subnet_egress[key] == "public_nat" && var.internet_ingress && local.primary_public_key != null
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
  count  = length(local.public_nat_subnet_map) > 0 ? 1 : 0
  domain = "vpc"
  public_ipv4_pool = "amazon"

  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  count = length(local.public_nat_subnet_map) > 0 ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[local.primary_public_key].id

  tags = {
    Name = "nat-gateway"
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

resource "aws_route" "private_nat" {
  for_each = local.public_nat_subnet_map

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnet_map

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id

  lifecycle {
    precondition {
      condition     = local.private_subnet_egress[each.key] != "public_nat" || (var.internet_ingress && local.primary_public_key != null)
      error_message = "Private subnets with egress = \"public_nat\" require internet_ingress = true and at least one public subnet."
    }
  }
}
