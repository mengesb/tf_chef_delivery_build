# AWS provider specific configs
variable "aws_access_key" {
  description = "Your AWS key (ex. $AWS_ACCESS_KEY_ID)"
}
variable "aws_secret_key" {
  description = "Your AWS secret (ex. $AWS_SECRET_ACCESS_KEY)"
}
variable "aws_key_name" {
  description = "Name of the key pair uploaded to AWS"
}
variable "aws_private_key_file" {
  description = "Full path to your local private key"
}
variable "aws_vpc_id" {
  description = "AWS VPC id (ex. vpc-ffffffff)"
}
variable "aws_subnet_id" {
  description = "AWS Subnet id (ex. subnet-ffffffff)"
}
variable "aws_ami_user" {
  description = "AWS AMI default username"
}
variable "aws_ami_id" {
  description = "AWS Instance ID (region dependent)"
  default = "ami-45844401"
}
variable "aws_flavor" {
  description = "AWS Instance type to deploy"
  default = "c3.xlarge"
}
variable "aws_region" {
  description = "AWS Region to deploy to"
  default = "us-west-1"
}
# tf_chef_delivery_server specific configs
variable "count" {
  description = "Number of CHEF Delivery build servers to provision"
  default = 5
}
variable "basename" {
  description = "Basename for AWS Name tag of CHEF Delivery server"
  default = "chef-delivery-build"
}
variable "chef_server_sg" {
  description = "The AWS security group of the CHEF Server"
}
variable "chef_delivery_sg" {
  description = "The AWS security group of the CHEF Delivery Server"
}
variable "chef_server_public_dns" {
  description = "The DNS address of the CHEF Server"
}
variable "chef_delivery_public_dns" {
  description = "The DNS address of CHEF Delivery"
}
variable "chef_org_short" {
  description = "Short CHEF Server organization name (lowercase alphanumeric characters only)"
}
variable "encrypted_data_bag_secret" {
  description = "The encrypted data bag secret"
}
variable "ssh_cidrs" {
  description = "List of CIDRs to allow SSH from"
  default = "0.0.0.0/0"
}
