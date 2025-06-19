# terraform/modules/it_infrastructure/variables.tf

variable "project_name" {}
variable "vpc_id" {}
variable "it_infra_private_subnet_id" {}
variable "blue_team_private_subnet_cidr" {} # Used for Security Group rules (e.g., allow WinRM from Blue Team)
variable "red_team_private_subnet_cidr" {}  # Used for Security Group rules (e.g., allow all from Red Team)
variable "key_pair_name" {}
variable "instance_type_windows_server" {}
variable "instance_type_windows_workstation" {}
variable "instance_type_docker_host" {}
variable "ami_windows_2019_base" {}
variable "ami_windows_10_pro" {}
variable "ami_ubuntu_2204" {} # For Docker Host
variable "your_public_ip" {}

# Common security group IDs passed from parent module (now from core_network outputs)
variable "ssh_from_your_ip_sg_id" {}
variable "rdp_from_your_ip_sg_id" {}
variable "it_infra_inbound_from_blue_red_sg_id" {}

# Removed:
# data "aws_subnet" "blue_team_private_subnet" {
#   id = var.blue_team_private_subnet_id
# }
# data "aws_subnet" "red_team_private_subnet" {
#   id = var.red_team_private_subnet_id
# }
# (or any other data blocks for SGs that might have been here)