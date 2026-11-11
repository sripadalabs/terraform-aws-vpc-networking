output "public_subnet_ids" {
  description = "IDs of the created public subnets."
  value       = { for k, subnet in aws_subnet.public : k => subnet.id }
}

output "private_subnet_ids" {
  description = "IDs of the created private subnets."
  value       = { for k, subnet in aws_subnet.private : k => subnet.id }
}

output "internet_gateway_id" {
  description = "Internet gateway ID if internet ingress is enabled."
  value       = var.internet_ingress ? aws_internet_gateway.this[0].id : null
}

output "nat_gateway_id" {
  description = "First public NAT gateway ID, retained for backward compatibility. Use public_nat_gateway_ids for all gateways."
  value       = length(aws_nat_gateway.this) > 0 ? values(aws_nat_gateway.this)[0].id : null
}

output "public_nat_gateway_ids" {
  description = "Public NAT gateway IDs keyed by availability zone."
  value       = { for az, gateway in aws_nat_gateway.this : az => gateway.id }
}

output "private_nat_gateway_ids" {
  description = "Private NAT gateway IDs keyed by private NAT subnet key."
  value       = { for key, gateway in aws_nat_gateway.private : key => gateway.id }
}
