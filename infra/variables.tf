variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "subnet_id" {
  description = "Optional specific subnet to use (must belong to the default VPC)"
  type        = string
  default     = ""
}

variable "http_cidr" {
  description = "CIDR allowed for HTTP 80"
  type        = string
  default     = "0.0.0.0/0"
}

variable "rdp_cidr" {
  description = "CIDR allowed for RDP 3389"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default = {
    Project = "one-project"
    Stack   = "infra"
    Owner   = "sms-codecloud"
  }
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


# MYSQL DB variables

variable "db_name" {
  description = "Database name to create"
  type        = string
  default     = "StudentDb"
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "adminuser"
}

variable "ssm_parameter_path" {
  description = "Path to store the app connection string"
  type        = string
  default     = "/one-project/mysql/connection"
}

variable "ssm_mysql_root_param" {
  type    = string
  default = "/one-project/mysql/root"
}

variable "app_pwd_param_name" {
  type = string
  default = "/one-project/mysql/app"
}


# Needed to decrypt Administrator password for WinRM connection:
variable "private_key_path" { 
  type = string 
  description = "Path to the private key matching the EC2 key pair"
  default = "D:/Git-CodeCloud/AWS/win-one-project-key-pair.pem"
  # e.g. "D:/keys/win-one-project-key-pair.pem"
}         

variable "db_admin_username" { 
  type = string  
  default = "adminuser"
}

variable "db_name" {
  type = string
  default = "StudentDb"
}