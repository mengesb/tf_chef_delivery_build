# Delivery Build AWS security group - https://github.com/chef-cookbooks/delivery-cluster
resource "aws_security_group" "delivery-build" {
  name        = "${var.basename}-xx.${var.domain} security group"
  description = "Delivery Build ${var.basename}-xx.${var.domain}"
  vpc_id      = "${var.aws_vpc_id}"
  tags        = {
    Name      = "${var.basename}-xx.${var.domain} security group"
  }
}
# SSH from Delivery
resource "aws_security_group_rule" "delivery-build_allow_delivery" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  source_security_group_id = "${var.delivery_sg}"
  security_group_id = "${aws_security_group.delivery-build.id}"
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
# AWS settings
provider "aws" {
  access_key  = "${var.aws_access_key}"
  secret_key  = "${var.aws_secret_key}"
  region      = "${var.aws_region}"
}
#
# Provisioning template
#
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
#
# Wait on
#
resource "null_resource" "wait_on" {
  provisioner "local-exec" {
    command = "echo Waited on ${var.wait_on} before proceeding"
  }
}
#
# Delivery build servers
#
resource "aws_instance" "delivery-build" {
  depends_on    = ["null_resource.wait_on"]
  count         = "${var.server_count}"
  ami           = "${lookup(var.ami_map, format("%s-%s", var.ami_os, var.aws_region))}"
  instance_type = "${var.aws_flavor}"
  associate_public_ip_address = "${var.public_ip}"
  subnet_id     = "${var.aws_subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.delivery-build.id}"]
  key_name      = "${var.aws_key_name}"
  tags = {
    Name        = "${format("%s-%02d.%s", var.basename, count.index + 1, var.domain)}"
    Description = "${var.tag_description}"
  }
  root_block_device = {
    delete_on_termination = "${var.root_delete_termination}"
  }
  connection {
    user        = "${lookup(var.ami_usermap, var.ami_os)}"
    private_key = "${var.aws_private_key_file}"
    host        = "${self.public_ip}"
  }
  provisioner "local-exec" {
    command = "knife node-delete ${format("%s-%02d.%s", var.basename, count.index + 1, var.domain)} -y ; echo OK"
  }
  provisioner "local-exec" {
    command = "knife client-delete ${format("%s-%02d.%s", var.basename, count.index + 1, var.domain)} -y ; echo OK"
  }
  # Provision with CHEF
  provisioner "chef" {
    attributes_json = "${element(template_file.attributes-json.*.rendered, count.index)}"
    environment     = "_default"
    log_to_file     = "${var.log_to_file}"
    node_name       = "${format("%s-%02d.%s", var.basename, count.index + 1, var.domain)}"
    run_list        = ["system::default","recipe[chef-client::default]","recipe[chef-client::config]","recipe[chef-client::cron]","recipe[chef-client::delete_validation]","delivery_build"]
    secret_key      = "${file("${var.secret_key_file}")}"
    server_url      = "https://${var.chef_fqdn}/organizations/${var.chef_org}"
    validation_client_name = "${var.chef_org}-validator"
    validation_key  = "${file("${var.chef_org_validator}")}"
    version         = "${var.client_version}"
  }
}

