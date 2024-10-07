
variable "aws" {
  description = "AWS configuration"
  type = object({
    region = string
  })
  default = {
    region = "us-east-1"
  }
}

variable "name" {
  description = "stack/cluster name, used in labelling across the stack."
  type        = string
}

variable "network" {
  description = "Network configuration"
  type = object({
    cidr               = string
    enable_vpn_gateway = bool
    enable_nat_gateway = bool
  })
  default = {
    cidr               = "172.31.0.0/16"
    enable_vpn_gateway = false
    enable_nat_gateway = false
  }
}

# === subnets ===
variable "subnets" {
  description = "The subnets configuration"
  type = map(object({
    cidr       = string
    nodegroups = list(string)
    private    = bool
  }))
  default = {}
}

variable "nodegroups" {
  description = "A map of machine group definitions"
  type = map(object({
    platform    = string
    type        = string
    count       = number
    volume_size = number
    role        = string
    public      = bool
    user_data   = string
    #    iam_profile_name = string
  }))
}

variable "extra_tags" {
  description = "Extra tags that will be added to all provisioned resources, where possible."
  type        = map(string)
  default     = {}
}

variable "windows_password" {
  description = "Password to use with windows & winrm"
  type        = string
  default     = ""
}

variable "ssh_pk_location" {
  description = "Location of the ssh private key"
  type        = string
  default     = ""
}
