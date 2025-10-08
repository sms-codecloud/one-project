# Reuse existing IGW if attached to the default VPC; otherwise create one.
data "aws_internet_gateways" "by_vpc" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_internet_gateway" "this" {
  count  = length(data.aws_internet_gateways.by_vpc.ids) == 0 ? 1 : 0
  vpc_id = data.aws_vpc.default.id
  tags   = merge(var.tags, { Name = "one-project-igw" })
}

locals {
  igw_id = length(data.aws_internet_gateways.by_vpc.ids) > 0
    ? data.aws_internet_gateways.by_vpc.ids[0]
    : aws_internet_gateway.this[0].id
}

# Create a dedicated public route table with default route to the IGW
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.default.id
  tags   = merge(var.tags, { Name = "one-project-public-rt" })
}

resource "aws_route" "public_default_to_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.igw_id
}

# Explicitly associate our public route table to the chosen subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = local.chosen_subnet_id
  route_table_id = aws_route_table.public.id
}
