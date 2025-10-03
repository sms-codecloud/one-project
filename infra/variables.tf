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

variable "my_ip_cidr" {
  type        = string
  description = "Public IPv4 you SSH from, CIDR (e.g. 49.207.145.12/32)."
  validation {
    condition     = can(cidrnetmask(var.my_ip_cidr))
    error_message = "my_ip_cidr must be a valid CIDR, like 203.0.113.10/32."
  }
}

variable "sql_sa_password" { 
    type = string  
    sensitive = true 
}      