# Default VPC
data "aws_vpc" "default" {
  default = true
}

# All subnets in the default VPC
data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Randomize subnet selection to pick a single default subnet
resource "random_shuffle" "subnet_picker" {
  input        = data.aws_subnets.default_vpc_subnets.ids
  result_count = 1
}

# Latest Windows Server 2022 AMI via SSM Parameter
data "aws_ssm_parameter" "win2022_ami" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
}

# Lookup latest public Windows Server 2022 AMI from Amazon (non-sensitive)
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
