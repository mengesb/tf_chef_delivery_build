# Delivery Build AWS security group - https://github.com/chef-cookbooks/delivery-cluster
resource "aws_security_group" "delivery-build" {
  name        = "delivery-build security group"
  description = "Delivery Build security group"
  vpc_id      = "${var.aws_vpc_id}"
  tags        = {
    Name      = "Delivery Build security group"
  }
}
# CHEF Server - all
resource "aws_security_group_rule" "delivery-build_allow_chef-server" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = "${var.chef_sg}"
  security_group_id = "${aws_security_group.delivery-build.id}"
}
# Delivery - all
resource "aws_security_group_rule" "delivery-build_allow_delivery" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = "${var.delivery_sg}"
  security_group_id = "${aws_security_group.delivery-build.id}"
}
# CHEF Server - allow all build servers
resource "aws_security_group_rule" "chef-server_allow_delivery-build" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = "${aws_security_group.delivery-build.id}"
  security_group_id = "${var.chef_sg}"
}
# Delivery - allow all from build servers
resource "aws_security_group_rule" "chef-delivery_allow_delivery-build" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  source_security_group_id = "${aws_security_group.delivery-build.id}"
  security_group_id = "${var.delivery_sg}"
}
# SSH - all
resource "aws_security_group_rule" "delivery-build_allow_22_tcp" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${split(",", var.allowed_cidrs)}"]
  security_group_id = "${aws_security_group.delivery-build.id}"
}
# Egress: ALL
resource "aws_security_group_rule" "delivery-build_allow_all" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.delivery-build.id}"
}
#
# Delivery build server requirements
resource "template_file" "attributes-json" {
  count       = "${var.server_count}"
  template    = "${file("${path.module}/files/attributes-json.tpl")}"
  vars {
    chef_fqdn = "${var.chef_fqdn}"
    chef_org  = "${var.chef_org}"
    host      = "${format("%s-%02d", var.basename, count.index + 1)}"
    domain    = "${var.domain}"
  }
}
resource "null_resource" "delivery-build-chef" {
  count     = "${var.server_count}"
  provisioner "local-exec" {
    command = "knife node-delete ${format("%s-%02d.%s", var.basename, count.index + 1, var.domain)} -y ; echo OK"
  }
  provisioner "local-exec" {
    command = "knife client-delete ${format("%s-%02d.%s", var.basename, count.index + 1, var.domain)} -y ; echo OK"
  }
}
#
# Delivery build servers
#
resource "aws_instance" "delivery-build" {
  depends_on    = ["null_resource.delivery-build-chef"]
  count         = "${var.server_count}"
  ami           = "${lookup(var.ami_map, format("%s-%s", var.ami_os, var.aws_region))}"
  instance_type = "${var.aws_flavor}"
  subnet_id     = "${var.aws_subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.delivery-build.id}"]
  key_name      = "${var.aws_key_name}"
  tags = {
    Name        = "${format("%s-%02d.%s", var.basename, count.index + 1, var.domain)}"
    Description = "${var.tag_description}"
  }
  root_block_device = {
    delete_on_termination = true
  }
  connection {
    user        = "${lookup(var.ami_usermap, var.ami_os)}"
    private_key = "${var.aws_private_key_file}"
    host        = "${self.public_ip}"
  }
  # Provision with CHEF
  provisioner "chef" {
    attributes_json = "${element(template_file.attributes-json.*.rendered, count.index)}"
    # environment = "_default"
    log_to_file = true
    node_name = "${format("%s-%02d.%s", var.basename, count.index + 1, var.domain)}"
    run_list = ["system::default","delivery_build"]
    secret_key = "${file("${var.secret_key_file}")}"
    server_url = "https://${var.chef_fqdn}/organizations/${var.chef_org}"
    validation_client_name = "${var.chef_org}-validator"
    validation_key = "${file("${var.chef_org_validator}")}"
  }
}
# Public Route53 DNS record
resource "aws_route53_record" "delivery-build" {
  count   = "${var.server_count}"
  zone_id = "${var.r53_zone_id}"
  name    = "${element(aws_instance.delivery-build.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.r53_ttl}"
  records = ["${element(aws_instance.delivery-build.*.public_ip, count.index)}"]
}
# Private Route53 DNS record
resource "aws_route53_record" "delivery-build-private" {
  count   = "${var.server_count}"
  zone_id = "${var.r53_zone_internal_id}"
  name    = "${element(aws_instance.delivery-build.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.r53_ttl}"
  records = ["${element(aws_instance.delivery-build.*.private_ip, count.index)}"]
}

