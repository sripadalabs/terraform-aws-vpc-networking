output "public_subnet_ids" {
  description = "IDs of the created public subnets."
  value       = { for k, subnet in aws_subnet.public : k => subnet.id }
}

output "private_with_internet_subnet_ids" {
  description = "IDs of the created private_with_internet subnets."
  value       = { for k, subnet in aws_subnet.private : k => subnet.id if subnet.subnet_type == "private_with_internet" }
}

output "private_with_internet_cidrs" {
  description = "CIDRs of the created private_with_internet subnets."
  value       = { for k, subnet in aws_subnet.private : k => subnet.cidr_block if subnet.subnet_type == "private_with_internet" }
}

output "private_with_internet_route_table_id" {
  description = "Route table ID of the created private_with_internet subnets."
  value = {
    for subnet in var.private_subnets :
    subnet.key => aws_route_table.private[subnet.key].id
    if subnet.subnet_type == "private_with_internet"
  }
}

output "private_only_route_table_id" {
  description = "Route table ID of the created private_only subnets."
  value = {
    for subnet in var.private_subnets :
    subnet.key => aws_route_table.private[subnet.key].id
    if subnet.subnet_type == "private_only"
  }
}

output "private_only_subnet_ids" {
  description = "IDs of the created private_only subnets."
  value       = { for k, subnet in aws_subnet.private : k => subnet.id if subnet.subnet_type == "private_only" }
}

output "private_only_cidrs" {
  description = "CIDRs of the created private_only subnets."
  value       = { for k, subnet in aws_subnet.private : k => subnet.cidr_block if subnet.subnet_type == "private_only" }
}

output "private_tgw_attachment_subnet_ids" {
  description = "IDs of the created private_tgw_attachment subnets."
  value       = { for k, subnet in aws_subnet.private : k => subnet.id if subnet.subnet_type == "private_tgw_attachment" }
}

output "private_tgw_attachment_cidrs" {
  description = "CIDRs of the created private_tgw_attachment subnets."
  value       = { for k, subnet in aws_subnet.private : k => subnet.cidr_block if subnet.subnet_type == "private_tgw_attachment" }
}

output "internet_gateway_id" {
  description = "Internet gateway ID if internet ingress is enabled."
  value       = var.internet_ingress ? aws_internet_gateway.this[0].id : null
}

output "public_nat_gateway_ids" {
  description = "Public NAT gateway IDs keyed by availability zone."
  value       = { for az, gateway in aws_nat_gateway.public_nat : az => gateway.id }
}
