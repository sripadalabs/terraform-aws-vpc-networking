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
      subnet.egress == null || contains(["none", "public_nat", "private_only"], subnet.egress)
    ])
    error_message = "Private subnet egress must be one of: none, public_nat, or private_only."
  }
}

variable "internet_ingress" {
  description = "Whether to create an internet gateway, public routing, and public NAT egress for private subnets that select it."
  type        = bool
  default     = false
}
