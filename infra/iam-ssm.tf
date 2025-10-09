# Store a full app connection string as a SecureString in SSM
# Example .NET MySQL connection string
locals {
  connection_string = "Server=${aws_db_instance.mysql.address};Port=3306;Database=${var.db_name};User Id=${var.db_username};Password=${random_password.db_master.result};TreatTinyAsBoolean=false;SslMode=None"
}

resource "aws_ssm_parameter" "mysql_conn" {
  name        = var.ssm_parameter_path
  description = "MySQL connection string for one-project app"
  type        = "SecureString"
  value       = local.connection_string
}

# Instance profile capable of reading the parameter
resource "aws_iam_role" "ec2_ssm_reader_role" {
  name               = "one-project-ec2-ssm-reader"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Inline policy to read the specific parameter
data "aws_iam_policy_document" "read_param" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory",
      "kms:Decrypt"
    ]
    resources = [
      aws_ssm_parameter.mysql_conn.arn
    ]
  }
}

resource "aws_iam_policy" "read_param_policy" {
  name   = "one-project-read-mysql-conn"
  policy = data.aws_iam_policy_document.read_param.json
}

resource "aws_iam_role_policy_attachment" "attach_reader" {
  role       = aws_iam_role.ec2_ssm_reader_role.name
  policy_arn = aws_iam_policy.read_param_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "one-project-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_reader_role.name
}

# (Optional) Attach instance profile to an existing EC2 by id
# NOTE: You can only have one instance profile attached; skip if you already use one.
# resource "aws_iam_instance_profile_association" "attach_existing" {
#   instance_id          = aws_instance.win.id
#   iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
# }