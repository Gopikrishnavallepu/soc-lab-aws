# terraform/modules/blue_team/variables.tf

variable "project_name" {}
variable "vpc_id" {}
variable "blue_team_private_subnet_id" {}
variable "blue_team_private_subnet_cidr" {
  description = "The CIDR block of the Blue Team private subnet."
  type        = string
}
variable "it_infra_private_subnet_cidr" {} # Used for Security Group rules (e.g., allow log traffic from this CIDR)
variable "key_pair_name" {}
variable "instance_type_so" {}
variable "instance_type_docker_host" {}
variable "ami_ubuntu_2204" {}
variable "your_public_ip" {}



# Common security group IDs passed from parent module (now from core_network outputs)
variable "ssh_from_your_ip_sg_id" {}
variable "blue_team_inbound_logs_sg_id" {}

# Removed:
# data "aws_subnet" "it_infra_private_subnet" {
#   id = var.it_infra_private_subnet_id
# }