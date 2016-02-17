# CHEF Delivery AWS security group - https://github.com/chef-cookbooks/delivery-cluster
resource "aws_security_group" "chef-delivery-build" {
  name = "chef-delivery-build"
  description = "CHEF Delivery Build"
  vpc_id = "${var.aws_vpc_id}"
  tags = {
    Name = "chef-delivery-build security group"
  }
}
# CHEF Server - all
resource "aws_security_group_rule" "chef-delivery-build_allow_chef-server_all" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  source_security_group_id = "${var.chef_server_sg}"
  security_group_id = "${aws_security_group.chef-delivery-build.id}"
}
# CHEF Delivery - all
resource "aws_security_group_rule" "chef-delivery-build_allow_chef-delivery_all" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  source_security_group_id = "${var.chef_delivery_sg}"
  security_group_id = "${aws_security_group.chef-delivery-build.id}"
}
# CHEF Server - allow all from build servers
resource "aws_security_group_rule" "chef-server_allow_chef-delivery-build_all" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  source_security_group_id = "${aws_security_group.chef-delivery-build.id}"
  security_group_id = "${var.chef_server_sg}"
}
# CHEF Delivery - allow all from build servers
resource "aws_security_group_rule" "chef-delivery_allow_chef-delivery-build_all" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  source_security_group_id = "${aws_security_group.chef-delivery-build.id}"
  security_group_id = "${var.chef_delivery_sg}"
}
# SSH - all
resource "aws_security_group_rule" "chef-delivery-build_allow_22_tcp_all" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["${split(",", var.ssh_cidrs)}"]
  security_group_id = "${aws_security_group.chef-delivery-build.id}"
}
# Egress: ALL
resource "aws_security_group_rule" "chef-delivery-build_allow_all" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.chef-delivery-build.id}"
}
# CHEF Delivery Build Servers
resource "aws_instance" "chef-delivery-build" {
  count = "${var.count}"
  ami = "${var.aws_ami_id}"
  instance_type = "${var.aws_flavor}"
  subnet_id = "${var.aws_subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.chef-delivery-build.id}"]
  key_name = "${var.aws_key_name}"
  tags = {
    Name = "${format("%s-%02d", var.basename, count.index + 1)}"
  }
  root_block_device = {
    delete_on_termination = true
  }
  connection {
    user = "${var.aws_ami_user}"
    private_key = "${var.aws_private_key_file}"
  }
  # Create required paths
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/.chef",
      "sudo mkdir -p /etc/chef"
    ]
  }
  # Hostname setup
  provisioner "remote-exec" {
    inline = [
      "EC2IPV4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)",
      "echo $EC2IPV4",
      "EC2FQDN=$(curl http://169.254.169.254/latest/meta-data/public-hostname)",
      "EC2HOST=$(echo $EC2FQDN | sed 's/..*//')",
      "EC2DOMA=$(echo $EC2FQDN | sed \"s/$EC2HOST.//\")",
      "sudo sed -i '/localhost/{n;s/^/${self.public_ip} ${self.public_dns}\\n/}' /etc/hosts",
      "[ -f /etc/sysconfig/network ] && sudo hostname ${self.public_dns} || sudo hostname $EC2HOST",
      "echo ${self.public_dns}|sed 's/\\..*//' > /tmp/hostname",
      "sudo chown root:root /tmp/hostname",
      "[ -f /etc/sysconfig/network ] && sudo sed -i 's/^HOSTNAME.*/HOSTNAME=${self.public_dns}/' /etc/sysconfig/network || sudo cp /tmp/hostname /etc/hostname",
      "sudo rm /tmp/hostname"
    ]
  }
  # Handle iptables
  provisioner "remote-exec" {
    inline = [
      "sudo iptables -F",
      "sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT",
      "sudo iptables -A INPUT -p icmp -j ACCEPT",
      "sudo iptables -A INPUT -i lo -j ACCEPT",
      "sudo iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT",
      "sudo iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited",
      "sudo iptables -A FORWARD -j REJECT --reject-with icmp-host-prohibited",
      "sudo service iptables save",
      "sudo service iptables restart"
    ]
  }
  # Copy over trusted certificates
  provisioner "file" {
    source = "${path.cwd}/.chef/trusted_certs"
    destination = "/tmp/.chef"
  }
  # Put files in proper locations
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/.chef/trusted_certs /etc/chef",
      "sudo chown -R root:root /etc/chef"
    ]
  }
  # BECAUSE PACKAGECLOUD SUCKS!
  provisioner "remote-exec" {
    inline = [
      "curl -s https://packagecloud.io/install/repositories/imeyer/runit/script.deb.sh -o /tmp/.chef/script.deb.sh",
      "curl -s https://packagecloud.io/install/repositories/imeyer/runit/script.rpm.sh -o /tmp/.chef/script.rpm.sh",
      "[ -x /usr/sbin/apt-get ] && sudo bash /tmp/.chef/script.deb.sh || sudo bash /tmp/.chef/script.rpm.sh",
      "[ -f /etc/yum.repos.d/imeyer_runit.repo ] && sudo sed -i 's|?dist=.&amp;os=el||g' /etc/yum.repos.d/imeyer_runit.repo",
      "[ -x /usr/bin/yum ] && sudo yum -q makecache -y --disablerepo=* --enablerepo=imeyer_runit",
      "[ -x /usr/bin/yum ] && sudo yum install -y pygpgme yum-utils",
      "[ -x /usr/sbin/apt-get ] && sudo apt-get install -y runit || sudo yum install -y runit",
      "rm -f /tmp/.chef/script.*.sh"
    ]
  }

  # Provision with CHEF
  provisioner "chef" {
    attributes {
      "delivery_build" {
        "delivery-cli" {
          "options" = "--nogpgcheck"
        }
      }
    }
    # environment = "_default"
    run_list = ["delivery_build"]
    node_name = "${format("%s-%02d", var.basename, count.index + 1)}"
    secret_key = "${file("${var.secret_key_file}")}"
    server_url = "https://${var.chef_server_dns}/organizations/${var.chef_org_short}"
    validation_client_name = "${var.chef_org_short}-validator"
    validation_key = "${file("${path.cwd}/.chef/${var.chef_org_short}-validator.pem")}"
  }
}
