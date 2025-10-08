locals {
  chosen_subnet_id = var.subnet_id != "" ? var.subnet_id : data.aws_subnets.default_vpc_subnets.ids[0]
  # igw_id = length(data.aws_internet_gateway.by_vpc.internet_gateway_id) > 0 ? data.aws_internet_gateway.by_vpc.internet_gateway_id : aws_internet_gateway.this[0].id

}
