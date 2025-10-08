locals {
  selected_subnet_id = random_shuffle.subnet_picker.result[0]
}