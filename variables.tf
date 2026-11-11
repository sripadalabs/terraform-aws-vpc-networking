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

  validation {
    condition     = length(distinct([for subnet in var.public_subnets : subnet.az])) == length(var.public_subnets)
    error_message = "Public subnets must have at most one subnet per availability zone."
  }
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
      subnet.egress == null || contains(["none", "public_nat", "private_only"], subnet.egress)
    ])
    error_message = "Private subnet egress must be one of: none, public_nat, or private_only."
  }

  validation {
    condition = alltrue([
      for subnet in var.private_subnets :
      (subnet.egress != null ? subnet.egress : (var.internet_ingress ? "public_nat" : "none")) != "public_nat" ||
      (
        var.internet_ingress &&
        anytrue([for public_subnet in var.public_subnets : public_subnet.az == subnet.az])
      )
    ])
    error_message = "Private subnets with effective egress = \"public_nat\" require internet_ingress = true and a public subnet in the same AZ."
  }
}

variable "internet_ingress" {
  description = "Whether to create an internet gateway, public routing, and public NAT egress for private subnets that select it."
  type        = bool
  default     = false
}
