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




# declare these since Jenkins passes them
variable "http_cidr" {
  type        = string
  description = "CIDR allowed to HTTP 80"
  default     = "0.0.0.0/0"
}

variable "rdp_cidr" {
  type        = string
  description = "CIDR allowed to RDP 3389"
  default     = "0.0.0.0/0"
}

# if you CREATE the VPC/Subnet inside this root, make these optional
variable "vpc_id" {
  type        = string
  description = "Existing VPC to deploy into (leave empty to create new)"
  default     = ""
}

variable "subnet_id" {
  type        = string
  description = "Existing Subnet to deploy into (leave empty to create new)"
  default     = ""
}

# required secrets (taken from Jenkins credentials)
variable "mysql_root_password" { type = string }
variable "mysql_app_password"  { type = string }
