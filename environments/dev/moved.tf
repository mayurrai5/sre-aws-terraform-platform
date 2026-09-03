# --------------------------------------------------
# Networking module refactor
# --------------------------------------------------

moved {
  from = aws_vpc.dev
  to   = module.networking.aws_vpc.this
}

moved {
  from = aws_subnet.public_a
  to   = module.networking.aws_subnet.public_a
}

moved {
  from = aws_subnet.public_b
  to   = module.networking.aws_subnet.public_b
}

moved {
  from = aws_subnet.private_a
  to   = module.networking.aws_subnet.private_a
}

moved {
  from = aws_subnet.private_b
  to   = module.networking.aws_subnet.private_b
}

moved {
  from = aws_internet_gateway.dev
  to   = module.networking.aws_internet_gateway.this
}

moved {
  from = aws_route_table.public
  to   = module.networking.aws_route_table.public
}

moved {
  from = aws_route_table.private
  to   = module.networking.aws_route_table.private
}

moved {
  from = aws_route_table_association.public_a
  to   = module.networking.aws_route_table_association.public_a
}

moved {
  from = aws_route_table_association.public_b
  to   = module.networking.aws_route_table_association.public_b
}

moved {
  from = aws_route_table_association.private_a
  to   = module.networking.aws_route_table_association.private_a
}

moved {
  from = aws_route_table_association.private_b
  to   = module.networking.aws_route_table_association.private_b
}

moved {
  from = aws_eip.nat
  to   = module.networking.aws_eip.nat
}

moved {
  from = aws_nat_gateway.dev
  to   = module.networking.aws_nat_gateway.this
}


# --------------------------------------------------
# IAM module refactor
# --------------------------------------------------

moved {
  from = aws_iam_role.ec2
  to   = module.iam.aws_iam_role.ec2
}

moved {
  from = aws_iam_role_policy_attachment.ssm
  to   = module.iam.aws_iam_role_policy_attachment.ssm
}

moved {
  from = aws_iam_instance_profile.ec2
  to   = module.iam.aws_iam_instance_profile.ec2
}
moved {
  from = aws_instance.private
  to   = module.compute.aws_instance.private
}