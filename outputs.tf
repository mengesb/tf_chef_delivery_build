output "public_ips" {
  value = "${join(",", aws_instance.delivery-build.*.public_ip)}"
}

