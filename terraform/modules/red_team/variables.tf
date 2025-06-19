# terraform/modules/red_team/variables.tf

variable "project_name" {}
variable "vpc_id" {}
variable "red_team_private_subnet_id" {}
variable "red_team_private_subnet_cidr" {
  description = "The CIDR block of the Red Team private subnet."
  type        = string
}
variable "it_infra_private_subnet_cidr" {} # Used for Security Group rules (e.g., allow Red Team attacks to IT Infra)
variable "key_pair_name" {}
variable "instance_type_docker_host" {}
variable "instance_type_kali_remnux" {} # Can be used for Kali
variable "ami_ubuntu_2204" {} # For Docker Host
variable "ami_kali_linux" {} # For Kali
variable "your_public_ip" {}

# Common security group IDs passed from parent module (now from core_network outputs)
variable "ssh_from_your_ip_sg_id" {}
variable "it_infra_inbound_from_blue_red_sg_id" {}

# Removed:
# data "aws_subnet" "it_infra_private_subnet" {
#   id = var.it_infra_private_subnet_id
# }
# (or any other data blocks for SGs that might have been here)