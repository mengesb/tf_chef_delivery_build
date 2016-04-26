tf_chef_delivery_build CHANGELOG
=============================

This file is used to list changes made in each version of the tf_chef_delivery_build Terraform plan.

v0.3.1 (2016-04-25)
-------------------
- [Brian Menges] - Remove delivery-cli customization in `attributes-json.tpl`

v0.3.0 (2016-04-25)
-------------------
- [Brian Menges] - Documentation updates
- [Brian Menges] - Implemented `wait_on` dependency chain usage
- [Brian Menges] - Added variables `wait_on`, `log_to_file`, `public_ip`, `root_delete_termination`, `client_version`
- [Brian Menges] - Updated `main.tf` to use new variables
- [Brian Menges] - Updated HEREDOC style usage in plan
- [Brian Menges] - Updated `attributes-json.tpl` and added chef_client
- [Brian Menges] - Specify provider so that defaults can be overwritten

v0.2.1 (2016-03-23)
-------------------
- [Brian Menges] - Added internal dns handles
- [Brian Menges] - Fixed server_count variable
- [Brian Menges] - Added system::default to run_list

v0.2.0 (2016-03-21)
-------------------
- [Brian Menges] - Brought code in line with other TF modules written
- [Brian Menges] - Added attributes-json.tpl
- [Brian Menges] - Style updates
- [Brian Menges] - Alphabetize variables and tidy things up

v0.1.2 (2016-02-16)
-------------------
- [Brian Menges] - Moved /tmp/.chef create up
- [Brian Menges] - packagecloud.io is awful, doing some bad things to cover for that

v0.1.1 (2016-02-15)
-------------------
- [Brian Menges] - Code cleanup and alignment with other tf_chef terraform modules written
- [Brian Menges] - Trim out some useless stuff
- [Brian Menges] - Variable updates per other module changes

v0.1.0 (2016-02-14)
-------------------
- [Brian Menges] - Initial commits and development

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
