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
    #egress      = optional(string)
    tags        = optional(map(string), {})
  }))
  default = []
}

variable "internet_ingress" {
  description = "Whether to create an internet gateway, public routing, and public NAT egress for private subnets that select it."
  type        = bool
  default     = false
}
