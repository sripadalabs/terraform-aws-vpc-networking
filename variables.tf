variable "vpc_id" {
  description = "The ID of the VPC where the subnets will be created."
  type        = string
}

variable "public_subnets" {
  description = "Public subnet definitions. Each item requires cidr, az, subnet_type, key, and optional tags."
  type = list(object({
    cidr        = string
    az          = string
    subnet_type = string
    key         = string
    tags        = optional(map(string), {})
  }))
  default = []
}

variable "private_subnets" {
  description = "Private subnet definitions. Each item requires cidr, az, subnet_type, and key; egress and tags are optional."
  type = list(object({
    cidr        = string
    az          = string
    subnet_type = string
    key         = string
    egress      = optional(string)
    tags        = optional(map(string), {})
  }))
  default = []

  validation {
    condition = alltrue([
      for subnet in var.private_subnets :
      subnet.egress == null || contains(["none", "public_nat", "private_only", "private_nat"], subnet.egress)
    ])
    error_message = "Private subnet egress must be one of: none, public_nat, private_only, or private_nat."
  }
}

variable "private_nat_subnets" {
  description = "Dedicated subnet definitions for private NAT gateways. Use one subnet per availability zone, separate from workload subnets."
  type = list(object({
    cidr        = string
    az          = string
    subnet_type = optional(string, "private_nat")
    key         = string
    tags        = optional(map(string), {})
  }))
  default = []

  validation {
    condition = (
      length(distinct([for subnet in var.private_nat_subnets : subnet.az])) == length(var.private_nat_subnets) &&
      length(distinct([for subnet in var.private_nat_subnets : subnet.key])) == length(var.private_nat_subnets)
    )
    error_message = "private_nat_subnets must use unique keys and contain at most one dedicated subnet per availability zone."
  }
}

variable "private_nat_destination_cidrs" {
  description = "Remote private destination CIDRs routed through private NAT gateways to the configured TGW or VGW."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.private_nat_destination_cidrs :
      can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"
    ])
    error_message = "Each private_nat_destination_cidrs value must be a valid IPv4 CIDR block other than 0.0.0.0/0."
  }

  validation {
    condition     = length(distinct(var.private_nat_destination_cidrs)) == length(var.private_nat_destination_cidrs)
    error_message = "private_nat_destination_cidrs must not contain duplicates."
  }
}

variable "private_nat_route_target_id" {
  description = "Transit Gateway or Virtual Private Gateway ID used by private NAT subnet route tables."
  type        = string
  default     = null

  validation {
    condition     = var.private_nat_route_target_id == null || trimspace(var.private_nat_route_target_id) != ""
    error_message = "private_nat_route_target_id must not be empty when set."
  }
}

variable "private_nat_route_target_type" {
  description = "Target type for private NAT subnet routes: transit_gateway or virtual_private_gateway."
  type        = string
  default     = null

  validation {
    condition     = var.private_nat_route_target_type == null || contains(["transit_gateway", "virtual_private_gateway"], var.private_nat_route_target_type)
    error_message = "private_nat_route_target_type must be transit_gateway or virtual_private_gateway."
  }
}

variable "internet_ingress" {
  description = "Whether to create an internet gateway, public routing, and public NAT egress for private subnets that select it."
  type        = bool
  default     = false
}
