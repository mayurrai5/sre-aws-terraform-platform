moved {
  from = aws_vpc.dev
  to   = module.networking.aws_vpc.this
}

moved {
  from = aws_subnet.public_a
  to   = module.networking.aws_subnet.public[0]
}

moved {
  from = aws_subnet.public_b
  to   = module.networking.aws_subnet.public[1]
}

moved {
  from = aws_subnet.private_a
  to   = module.networking.aws_subnet.private[0]
}

moved {
  from = aws_subnet.private_b
  to   = module.networking.aws_subnet.private[1]
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
  to   = module.networking.aws_route_table_association.public[0]
}

moved {
  from = aws_route_table_association.public_b
  to   = module.networking.aws_route_table_association.public[1]
}

moved {
  from = aws_route_table_association.private_a
  to   = module.networking.aws_route_table_association.private[0]
}

moved {
  from = aws_route_table_association.private_b
  to   = module.networking.aws_route_table_association.private[1]
}

moved {
  from = aws_eip.nat
  to   = module.networking.aws_eip.nat
}

moved {
  from = aws_nat_gateway.dev
  to   = module.networking.aws_nat_gateway.this
}