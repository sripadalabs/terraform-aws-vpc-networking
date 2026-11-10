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
  description = "Private subnet definitions. Each item requires cidr, az, subnet_type, key, and optional tags."
  type = list(object({
    cidr        = string
    az          = string
    subnet_type = string
    key         = string
    tags        = optional(map(string), {})
  }))
  default = []
}

variable "internet_ingress" {
  description = "Whether to create an internet gateway, public routing, and NAT resources."
  type        = bool
  default     = false
}
