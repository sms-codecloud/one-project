locals {
  use_existing_net = var.vpc_id != "" && var.subnet_id != ""
  effective_vpc_id   = local.use_existing_net ? var.vpc_id   : aws_vpc.this[0].id
  effective_subnet_id= local.use_existing_net ? var.subnet_id: aws_subnet.this[0].id
}