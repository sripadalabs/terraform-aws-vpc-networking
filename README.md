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
| `private_subnets` | `list(object)` | Private subnet definitions with `cidr`, `az`, `subnet_type`, `key`, `tags` |
| `internet_ingress` | `bool` | Enables internet gateway and relevant route resources |

The `az` field in both subnet inputs is an availability-zone name (for example, `us-east-1a`) and is assigned to the subnet's `availability_zone`.

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
      tags        = { Environment = "dev" }
    }
  ]

  internet_ingress = true
}
```

## Notes
- Public subnets automatically get a Name tag of `Public subnet ${az}`.
- Private subnets get routing through a NAT gateway when `internet_ingress` is enabled and private subnets are defined.
- The module is designed for Terraform 1.x and AWS provider 5.x+.
