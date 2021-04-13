output "vpc_id" {
  value = aws_vpc.default.id
}
output "pub_ids" {
  value = [aws_subnet.publics.*.id]
}
output "pri_ids" {
  value = [aws_subnet.privates.*.id]
}