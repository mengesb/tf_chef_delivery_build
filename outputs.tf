output "public_ips" {
  value = "${join(",", aws_instance.chef-delivery-build.*.public_ip)}"
}
