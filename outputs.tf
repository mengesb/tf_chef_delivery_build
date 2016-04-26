output "fqdns" {
  value = "${join(",", aws_instance.delivery-build.*.tags.Name)}"
}
output "private_ips" {
  value = "${join(",", aws_instance.delivery-build.*.public_ip)}"
}
output "public_ips" {
  value = "${join(",", aws_instance.delivery-build.*.public_ip)}"
}

