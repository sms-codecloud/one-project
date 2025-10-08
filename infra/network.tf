# resource "aws_internet_gateway" "this" {
#   count  = length(data.aws_internet_gateway.by_vpc.internet_gateway_id) == 0 ? 1 : 0
#   vpc_id = data.aws_vpc.default.id
#   tags   = merge(var.tags, { Name = "one-project-igw" })
# }

# # Create a dedicated public route table with default route to the IGW
# resource "aws_route_table" "public" {
#   vpc_id = data.aws_vpc.default.id
#   tags   = merge(var.tags, { Name = "one-project-public-rt" })
# }

# resource "aws_route" "public_default_to_igw" {
#   route_table_id         = aws_route_table.public.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = local.igw_id
# }

# # Explicitly associate our public route table to the chosen subnet
# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = local.chosen_subnet_id
#   route_table_id = aws_route_table.public.id
# }
