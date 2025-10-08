locals {
  selected_subnet_id = random_shuffle.subnet_picker.result[0]

  # Pick the main route table from the set (Associations[*].Main contains true for the main one)
  main_rtb_id = one(flatten([
    for rt in data.aws_route_tables.main_for_default_vpc.ids : [
      rt
    ]
  ]))

}