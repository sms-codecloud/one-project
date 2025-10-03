variable "region"{ 
    type = string  
    default = "ap-south-1" 
}
variable "key_name" { 
    type = string 
    default = "one-project-key-pair"
}
                         
variable "instance_type" { 
    type = string  
    default = "t3.small" 
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH (port 22)."
  validation {
    condition     = alltrue([for c in var.allowed_ssh_cidrs : can(cidrnetmask(c))])
    error_message = "Each entry must be a valid CIDR (e.g., 203.0.113.10/32)."
  }
}

variable "sql_sa_password" { 
    type = string  
    sensitive = true 
}      