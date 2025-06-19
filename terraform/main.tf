# terraform/main.tf

# ---------------------------------------------------
# Main SOC Lab Infrastructure Orchestration
# This file calls the individual modules.
# Modules are commented out by default and selectively uncommented by the Python script.
# ---------------------------------------------------

# 1. Core Network Module (VPC, Subnets, NAT Instance, IGW, and common SGs)
# This module MUST be deployed first using the Python script.
# Ensure this module block appears ONLY ONCE in this file.
module "core_network" {
  source            = "./modules/core_network"
  project_name      = var.project_name
  aws_region        = var.aws_region
  key_pair_name     = var.key_pair_name
  your_public_ip    = var.your_public_ip
  instance_type_nat = var.instance_type_nat
  ami_ubuntu_2204   = var.ami_ubuntu_2204 # For the NAT Instance
}

# --- Team Modules ---
# Each team module is wrapped in its own multi-line comment.
# The Python script will uncomment the selected module for deployment.

# 2. Blue Team Operations Module
/*

module "blue_team" {
  source                      = "./modules/blue_team"
  project_name                = var.project_name
  vpc_id                      = module.core_network.vpc_id
  blue_team_private_subnet_id = module.core_network.blue_team_private_subnet_id
  blue_team_private_subnet_cidr = module.core_network.blue_team_private_subnet_cidr # ADD THIS LINE
  it_infra_private_subnet_cidr = module.core_network.it_infra_private_subnet_cidr # For SG rules
  key_pair_name               = var.key_pair_name
  instance_type_so            = var.instance_type_so
  instance_type_docker_host   = var.instance_type_docker_host
  ami_ubuntu_2204             = var.ami_ubuntu_2204
  your_public_ip              = var.your_public_ip
  ssh_from_your_ip_sg_id      = module.core_network.ssh_from_your_ip_sg_id
  blue_team_inbound_logs_sg_id = module.core_network.blue_team_inbound_logs_sg_id
}

*/
# 3. Red Team Operations Module
/*

module "red_team" {
  source                      = "./modules/red_team"
  project_name                = var.project_name
  vpc_id                      = module.core_network.vpc_id
  red_team_private_subnet_id  = module.core_network.red_team_private_subnet_id
  red_team_private_subnet_cidr = module.core_network.red_team_private_subnet_cidr # ADD THIS LINE
  it_infra_private_subnet_cidr = module.core_network.it_infra_private_subnet_cidr # For SG rules
  key_pair_name               = var.key_pair_name
  instance_type_docker_host   = var.instance_type_docker_host
  instance_type_kali_remnux   = var.instance_type_kali_remnux
  ami_ubuntu_2204             = var.ami_ubuntu_2204 # For Docker Host
  ami_kali_linux              = var.ami_kali_linux  # For Kali
  your_public_ip              = var.your_public_ip
  ssh_from_your_ip_sg_id      = module.core_network.ssh_from_your_ip_sg_id
  it_infra_inbound_from_blue_red_sg_id = module.core_network.it_infra_inbound_from_blue_red_sg_id
}

*/
# 4. Forensic Operations Module
/*

module "forensics_team" {
  source                      = "./modules/forensics_team"
  project_name                = var.project_name
  vpc_id                      = module.core_network.vpc_id
  forensics_private_subnet_id = module.core_network.forensics_private_subnet_id
  key_pair_name               = var.key_pair_name
  instance_type_kali_remnux   = var.instance_type_kali_remnux # For REMnux
  instance_type_windows_workstation = var.instance_type_windows_workstation # For Flare VM
  ami_remnux                  = var.ami_remnux
  ami_flare_vm                = var.ami_flare_vm
  your_public_ip              = var.your_public_ip
  ssh_from_your_ip_sg_id      = module.core_network.ssh_from_your_ip_sg_id
  rdp_from_your_ip_sg_id      = module.core_network.rdp_from_your_ip_sg_id
}

*/
# 5. IT Infrastructure Department Module
/*

module "it_infrastructure" {
  source                      = "./modules/it_infrastructure"
  project_name                = var.project_name
  vpc_id                      = module.core_network.vpc_id
  it_infra_private_subnet_id  = module.core_network.it_infra_private_subnet_id
  blue_team_private_subnet_cidr = module.core_network.blue_team_private_subnet_cidr # For SG rules
  red_team_private_subnet_cidr  = module.core_network.red_team_private_subnet_cidr  # For SG rules
  key_pair_name               = var.key_pair_name
  instance_type_windows_server = var.instance_type_windows_server
  instance_type_windows_workstation = var.instance_type_windows_workstation
  instance_type_docker_host   = var.instance_type_docker_host
  ami_windows_2019_base       = var.ami_windows_2019_base
  ami_windows_10_pro          = var.ami_windows_10_pro
  ami_ubuntu_2204             = var.ami_ubuntu_2204
  your_public_ip              = var.your_public_ip
  ssh_from_your_ip_sg_id      = module.core_network.ssh_from_your_ip_sg_id
  rdp_from_your_ip_sg_id      = module.core_network.rdp_from_your_ip_sg_id
  it_infra_inbound_from_blue_red_sg_id = module.core_network.it_infra_inbound_from_blue_red_sg_id
}

*/
