# tf_chef_delivery_build
Terraform module to setup CHEF Delivery build nodes. Requires CHEF Server and Delivery

## Assumptions

* Requires:
  * AWS (duh!)
  * AWS subnet id
  * AWS VPC id
  * SSL certificate/key for created instance
* Uses a public IP and public DNS
* Default security group implementation
  * 22/tcp: SSH
* Understand Terraform and ability to read the source

## Supported OSes
All supported OSes are 64-bit and HVM (though PV should be supported)

* Ubuntu 12.04 LTS
* Ubuntu 14.04 LTS
* Ubuntu 16.04 LTS (pending)
* CentOS 6 (Default)
* CentOS 7 (pending)
* Others (here be dragons! Please see Map Variables)

## AWS

These resources will incur charges on your AWS bill. It is your responsibility to delete the resources.

## Input variables

### AWS variables

* `aws_access_key`: Your AWS key, usually referred to as `AWS_ACCESS_KEY_ID`
* `aws_flavor`: The AWS instance type. Default: `c3.xlarge`
* `aws_key_name`: The private key pair name on AWS to use (String)
* `aws_private_key_file`: The full path to the private kye matching `aws_key_name` public key on AWS
* `aws_region`: AWS region you want to deploy to. Default: `us-west-1`
* `aws_secret_key`: Your secret for your AWS key, usually referred to as `AWS_SECRET_ACCESS_KEY`
* `aws_subnet_id`: The AWS id of the subnet to use. Example: `subnet-ffffffff`
* `aws_vpc_id`: The AWS id of the VPC to use. Example: `vpc-ffffffff`

### tf_chef_delivery_build variables

* `allowed_cidrs`: The comma seperated list of addresses in CIDR format to allow SSH access. Default `0.0.0.0/0`
* `basename`: Delivery build node basenames. Default: `delivery-build`
* `domain`: Delivery server's domain. Default: 'localdomain'
* `knife_rb`: Path to your knife.rb file
* `chef_fqdn`: DNS address of the CHEF Server.
* `chef_org`: CHEF Server short organization name.
* `chef_sg`: CHEF Server security group id.
* `delivery_sg`: Delivery server security group id.
* `r53`: Boolean determines if Route53 will be used or not. Default: `0`
* `r53_ttl`: Time to Live (TTL) setting for Route53 A record to be created. Default: `180`
* `r53_zone_id`: AWS Route53 Zone ID to add an A record for the build servers
* `r53_zone_id`: AWS Route53 Internal Zone ID to add an A record for the build servers
* `secret_key_file`: Encrypted data bag secret key file.
* `server_count`: Count of build nodes to create. Default: `5`
* `tag_description`: Text field tag 'Description'

### Map variables

The below mapping variables construct selection criteria

* `ami_map`: AMI selection map comprised of `ami_os` and `aws_region`
* `ami_usermap`: Default username selection map based off `ami_os`

The `ami_map` is a combination of `ami_os` and `aws_region` which declares the AMI selected. To override this pre-declared AMI, define

```
ami_map.<ami_os>-<aws_region> = "value"
```

Variable `ami_os` should be one of the following:

* centos6 (default)
* centos7
* ubuntu12
* ubuntu14
* ubuntu16

Variable `aws_region` should be one of the following:

* us-east-1
* us-west-2
* us-west-1 (default)
* eu-central-1
* eu-west-1
* ap-southeast-1
* ap-southeast-2
* ap-northeast-1
* ap-northeast-2
* sa-east-1
* Custom (must be an AWS region, requires setting `ami_map` and setting AMI value)

Map `ami_usermap` uses `ami_os` to look the default username for interracting with the instance. To override this pre-declared user, define

```
ami_usermap.<ami_os> = "value"
```

## Outputs

* `build_ips`: A CSV of public IPs for the build servers created

## Contributors

* [Brian Menges](https://github.com/mengesb)
* [Salim Afiune](https://github.com/afiune)

## Contributing

Please understand that this is a work in progress and is subject to change rapidly. Please be sure to keep up to date with the repo should you fork, and feel free to contact me regarding development and suggested direction

## `CHANGELOG`

Please refer to the [`CHANGELOG.md`](CHANGELOG.md)

## License

This is licensed undert [the Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0).
