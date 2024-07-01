output "vpc_id" {
  value = aws_vpc.dev.id
}

output "mysql_subnet_list" {
  value = aws_subnet.mysql_subnet.*.id
}

output "frontend_subnet_list" {
  value = aws_subnet.frontend_subnet.*.id
}

output "backend_subnet_list" {
  value = aws_subnet.backend_subnet.*.id
}

output "lb_subnets_list" {
  value = aws_subnet.public_subnet.*.id
}