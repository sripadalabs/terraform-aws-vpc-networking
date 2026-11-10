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
  description = "Public NAT gateway ID if any private subnet uses public_nat egress."
  value       = length(aws_nat_gateway.this) > 0 ? aws_nat_gateway.this[0].id : null
}
