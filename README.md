# Terraform AWS VPC Networking Module

This module creates VPC subnets and networking resources for a given VPC, supporting both public and private subnet definitions.

## Included resources
- `aws_subnet.public`
- `aws_subnet.private`
- `aws_subnet.private_nat`
- `aws_internet_gateway`
- `aws_route_table` (public and private)
- `aws_route`
- `aws_route_table_association`
- `aws_eip`
- `aws_nat_gateway`

## Inputs
| Name | Type | Description |
| --- | --- | --- |
| `vpc_id` | `string` | VPC ID to attach resources to |
| `public_subnets` | `list(object)` | Public subnet definitions with `cidr`, `az`, `subnet_type`, `key`, `tags` |
| `private_subnets` | `list(object)` | Private subnet definitions with `cidr`, `az`, `subnet_type`, `key`, optional `egress`, and `tags` |
| `internet_ingress` | `bool` | Enables the internet gateway, public routing, and public NAT egress when selected |
| `private_nat_subnets` | `list(object)` | Dedicated private NAT gateway subnets, with one subnet per AZ used by `private_nat` workloads |
| `private_nat_destination_cidrs` | `list(string)` | Remote private CIDRs routed through private NAT gateways |
| `private_nat_route_target_id` | `string` | Transit Gateway or Virtual Private Gateway ID for onward routes |
| `private_nat_route_target_type` | `string` | `transit_gateway` or `virtual_private_gateway` |

The `az` field in both subnet inputs is an availability-zone name (for example, `us-east-1a`) and is assigned to the subnet's `availability_zone`.

Each private subnet can set `egress` to `none`, `public_nat`, `private_only`, or `private_nat`. `none` and `private_only` have no outbound route beyond the VPC-local route, so same-VPC communication continues to use that local route. `public_nat` adds a default route through the public NAT gateway and requires `internet_ingress = true` and at least one public subnet. If `egress` is omitted, it defaults to the legacy behavior: `public_nat` when `internet_ingress` is true, otherwise `none`.

`private_nat` routes only the configured `private_nat_destination_cidrs` from a workload subnet to the private NAT gateway in the same AZ; it does not provide internet egress. Configure one dedicated `private_nat_subnets` subnet per workload AZ, plus `private_nat_route_target_id` and `private_nat_route_target_type` to send those CIDRs from the NAT subnet onward through a Transit Gateway or Virtual Private Gateway already attached to the VPC. Keep private NAT subnets separate from workload subnets and specify only remote CIDRs; same-VPC traffic uses the VPC-local route.

Public subnet and internet gateway/public routing resources are defined in `public.tf`. Private subnet, NAT gateway, and private routing resources are defined in `private.tf`.

## Example
```hcl
module "vpc_networking" {
  source = "./terraform-aws-vpc-networking"

  vpc_id = module.vpc.vpc_id

  public_subnets = [
    {
      cidr        = "10.0.1.0/24"
      az          = "us-east-1a"
      subnet_type = "public"
      key         = "public-a"
      tags        = { Environment = "dev" }
    }
  ]

  private_subnets = [
    {
      cidr        = "10.0.11.0/24"
      az          = "us-east-1a"
      subnet_type = "private"
      key         = "private-a"
      egress      = "public_nat"
      tags        = { Environment = "dev" }
    },
    {
      cidr        = "10.0.12.0/24"
      az          = "us-east-1b"
      subnet_type = "private"
      key         = "private-b"
      egress      = "private_nat"
      tags        = { Environment = "dev" }
    }
  ]

  internet_ingress = true

  private_nat_subnets = [
    {
      cidr = "10.0.21.0/24"
      az   = "us-east-1b"
      key  = "private-nat-b"
    }
  ]

  private_nat_destination_cidrs = ["10.1.0.0/16"]
  private_nat_route_target_id   = "tgw-0123456789abcdef0"
  private_nat_route_target_type = "transit_gateway"
}
```

## Notes
- Public subnets automatically get a Name tag of `Public subnet ${az}`.
- Private subnets get a public NAT default route only when their effective egress mode is `public_nat`; `private_nat` creates private NAT gateways without EIPs and routes only configured remote CIDRs.
- The module is designed for Terraform 1.x and AWS provider 5.x+.
