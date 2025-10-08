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

# Create an Internet Gateway if the default VPC doesn't have one
resource "aws_internet_gateway" "default_vpc_igw" {
  vpc_id = data.aws_vpc.default.id
}

# Get the MAIN route table of the default VPC
data "aws_route_tables" "main_for_default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Safer: explicitly fetch the main route table
data "aws_route_table" "main" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "association.main"
    values = ["true"]
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


