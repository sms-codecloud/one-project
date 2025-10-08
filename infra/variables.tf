variable "region" {
  type        = string
  description = "AWS region (e.g., ap-south-1)"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.small"
}

variable "key_name" {
  type        = string
  description = "Optional EC2 key pair (null if empty to rely on SSM only)"
  default     = ""
}

variable "http_cidr" {
  type        = string
  description = "CIDR allowed to access HTTP (80)"
  default     = "0.0.0.0/0"
}

variable "rdp_cidr" {
  type        = string
  description = "CIDR allowed to access RDP (3389)"
  default     = "0.0.0.0/0"
}

# Required app secrets (these are passed via TF_VAR_… from Jenkins)
variable "mysql_root_password" {
  type        = string
  description = "MySQL root password"
  sensitive   = true
}

variable "mysql_app_password" {
  type        = string
  description = "MySQL app/user password"
  sensitive   = true
}
