output "vpc_id" {
  description = "ID of the development VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_a_id" {
  description = "ID of private subnet A"
  value       = module.networking.private_subnet_ids[0]
}

output "private_subnet_b_id" {
  description = "ID of private subnet B"
  value       = module.networking.private_subnet_ids[1]
}