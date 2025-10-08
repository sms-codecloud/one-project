# # Reuse existing IGW if attached to the default VPC; otherwise create one.
# data "aws_internet_gateway" "by_vpc" {
#   filter {
#     name   = "attachment.vpc-id"
#     values = [data.aws_vpc.default.id]
#   }
# }

# Default VPC and its subnets
data "aws_vpc" "default" {
  default = true
}


data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Windows Server 2022 English Full Base AMI
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["801119661308"] # Amazon Windows AMIs

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
