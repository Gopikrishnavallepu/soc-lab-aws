# terraform/modules/forensics_team/variables.tf

variable "project_name" {}
variable "vpc_id" {}
variable "forensics_private_subnet_id" {}
variable "key_pair_name" {}
variable "instance_type_kali_remnux" {} # Can be used for REMnux
variable "instance_type_windows_workstation" {} # Can be used for Flare VM
variable "ami_remnux" {}
variable "ami_flare_vm" {}
variable "your_public_ip" {}

# Common security group IDs passed from parent module (now from core_network outputs)
variable "ssh_from_your_ip_sg_id" {}
variable "rdp_from_your_ip_sg_id" {}

# Removed:
# (any data blocks for SGs that might have been here)