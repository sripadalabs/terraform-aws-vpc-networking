# Terraform AWS VPC Networking Module

This module creates VPC subnets and networking resources for a given VPC, supporting both public and private subnet definitions.

## Included resources
- `aws_subnet.public`
- `aws_subnet.private`
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

The `az` field in both subnet inputs is an availability-zone name (for example, `us-east-1a`) and is assigned to the subnet's `availability_zone`.

Each private subnet can set `egress` to `none`, `public_nat`, or `private_only`. `none` and `private_only` have no outbound route beyond the VPC-local route, so same-VPC communication continues to use that local route. `public_nat` adds a default route through a public NAT gateway in the same AZ and requires `internet_ingress = true` and a public subnet in every AZ that uses this mode. The module creates one public NAT gateway and EIP per such AZ. If `egress` is omitted, it defaults to the legacy behavior: `public_nat` when `internet_ingress` is true, otherwise `none`.

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
    }
  ]

  internet_ingress = true
}
```

## Notes
- Public subnets automatically get a Name tag of `Public subnet ${az}`.
- Private subnets get a default route through their AZ-local public NAT gateway only when their effective egress mode is `public_nat`; `public_nat_gateway_ids` returns every public NAT gateway ID keyed by AZ. The legacy `nat_gateway_id` output remains available and returns the first ID.
- The module is designed for Terraform 1.x and AWS provider 5.x+.
