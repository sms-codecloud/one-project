variable "region"           { type = string  default = "ap-south-1" }
variable "key_name"         { type = string }                         # existing EC2 keypair name
variable "my_ip_cidr"       { type = string }                         # e.g. "203.0.113.10/32"
variable "instance_type"    { type = string  default = "t3.small" }
variable "sa_password"      { type = string  sensitive = true }       # strong SA password
variable "github_repo_url"  { type = string }                         # used on first-boot optional clone
