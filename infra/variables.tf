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
    type = string
    default = "0.0.0.0/0"
}

variable "sql_sa_password" { 
    type = string  
    sensitive = true 
}      