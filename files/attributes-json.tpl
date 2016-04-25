{
  "chef_client": {
    "init_style": "none"
  },
  "delivery_build": {
    "delivery-cli": {
      "options": "--nogpgcheck"
    }
  },
  "fqdn": "${host}.${domain}",
  "firewall": {
    "allow_established": true,
    "allow_ssh": true
  },
  "system": {
    "short_hostname": "${host}",
    "domain_name": "${domain}",
    "manage_hostsfile": true
  },
  "tags": []
}
