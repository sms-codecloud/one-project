variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "key_name" {
  type    = string
  default = "one-project-key-pair"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH (22)."
  validation {
    condition     = alltrue([for c in var.allowed_ssh_cidrs : can(cidrnetmask(c))])
    error_message = "Each entry must be a valid CIDR (e.g., 203.0.113.10/32)."
  }
}

# NEW: app DB user password for MySQL on the EC2 box
variable "mysql_app_password" {
  type      = string
  sensitive = true
}

variable "mysql_db" {
  type    = string
  default = "studentdb"
}

variable "mysql_user" {
  type    = string
  default = "studentapp"
}

variable "mysql_app_password" {
  type      = string
  sensitive = true
}
