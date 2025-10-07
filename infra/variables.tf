# --- Variables ---
variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "one-project"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "key_name" {
  type      = string
  default   = null
  nullable  = true
  sensitive = false
}

variable "iam_instance_profile" {
  type      = string
  default   = null
  nullable  = true
}

# Keep RDP open by default (you can restrict later to your office IPs)
variable "rdp_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "mysql_root_password" {
  type      = string
  sensitive = true
}

variable "mysql_app_password" {
  type      = string
  sensitive = true
}

variable "common_tags" {
  type = map(string)
  default = {
    Project   = "one-project"
    ManagedBy = "Terraform"
  }
}
