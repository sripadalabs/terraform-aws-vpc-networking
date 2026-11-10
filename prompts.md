# Reference prompt

Create a new Terraform module named `terraform-aws-vpc-networking`.

Requirements:
- Create subnets for a supplied VPC id.
- Accept `vpc_id` as input.
- Accept `public_subnets` and `private_subnets` as lists of objects containing `cidr`, `az`, `subnet_type`, `key`, and optional `tags`.
- Accept `internet_ingress` as a boolean flag.
- Create public subnets using `aws_subnet` with `vpc_id`, `cidr_block`, `availability_zone` from the supplied AZ name, `private_dns_hostname_type_on_launch`, and tags.
- Add public subnet tag: `Name = "Public subnet ${each.value.az}"`.
- Keep private subnet, NAT gateway, and private routing resources in `private.tf`; keep public subnet, internet gateway, and public routing resources in `public.tf`.
- When `internet_ingress` is true, create `aws_internet_gateway`, `aws_route_table`, `aws_route`, `aws_route_table_association`, `aws_eip`, and `aws_nat_gateway`.
- Ensure private subnets have NAT-backed default routes when appropriate.
- Keep the module reusable and production-friendly.
