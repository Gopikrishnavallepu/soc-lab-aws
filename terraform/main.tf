# terraform/main.tf

# Locals block to read custom_amis.json for dynamic AMI selection
locals {
  # Path to custom_amis.json from the root terraform directory
  custom_amis_file_path = "${path.root}/custom_amis.json"
  # Read the JSON file if it exists, otherwise initialize as an empty map
  custom_amis = fileexists(local.custom_amis_file_path) ? jsondecode(file(local.custom_amis_file_path)) : {}
}

# ---------------------------------------------------
# Main SOC Lab Infrastructure Orchestration
# This file calls the individual modules.
# Modules are commented out by default and selectively uncommented by the Python script.
# ---------------------------------------------------

# 1. Core Network Module (VPC, Subnets, NAT Instance, IGW, and common SGs)
# This module MUST be deployed first. It is typically always enabled for the lab to function.
module "core_network" {
  source            = "./modules/core_network"
  project_name      = var.project_name
  aws_region        = var.aws_region
  key_pair_name     = var.key_pair_name
  your_public_ip    = var.your_public_ip
  instance_type_nat = var.instance_type_nat

  # Outputs from core_network will be used as inputs for other modules
  # Example: blue_team_private_subnet_id, ssh_from_your_ip_sg_id, etc.
}

# --- Team Modules ---
# Each team module is wrapped in its own multi-line comment.
# The Python script (main.py) will uncomment the selected module for deployment
# and re-comment it after destruction or upon exiting the script.

# 2. Blue Team Operations Module
/*
module "blue_team" {
  source              = "./modules/blue_team"
  project_name        = var.project_name
  aws_region          = var.aws_region
  key_pair_name       = var.key_pair_name
  your_public_ip      = var.your_public_ip
  vpc_id              = module.core_network.vpc_id
  
  # Pass specific private subnet ID for the blue team
  blue_team_private_subnet_id = module.core_network.blue_team_private_subnet_id
  
  # Pass CIDR blocks for SG rules (if modules need to reference each other's networks)
  blue_team_private_subnet_cidr = module.core_network.blue_team_private_subnet_cidr
  it_infra_private_subnet_cidr = module.core_network.it_infra_private_subnet_cidr # For SG rules (e.g., logs from IT Infra)

  ami_ubuntu_2204     = var.ami_ubuntu_2204 # Fallback if custom AMI not found
  instance_type_so    = var.instance_type_so
  instance_type_docker_host = var.instance_type_docker_host
  
  # Pass specific Security Group IDs needed by this module
  ssh_from_your_ip_sg_id = module.core_network.ssh_from_your_ip_sg_id
  blue_team_inbound_logs_sg_id = module.core_network.blue_team_inbound_logs_sg_id # For SIEM log ingestion
  # ... other SGs as needed for internal communication within Blue Team
}
*/

# 3. Red Team Operations Module
/*
module "red_team" {
  source              = "./modules/red_team"
  project_name        = var.project_name
  aws_region          = var.aws_region
  key_pair_name       = var.key_pair_name
  your_public_ip      = var.your_public_ip
  vpc_id              = module.core_network.vpc_id
  
  red_team_private_subnet_id = module.core_network.red_team_private_subnet_id
  red_team_private_subnet_cidr = module.core_network.red_team_private_subnet_cidr # For SG rules
  it_infra_private_subnet_cidr = module.core_network.it_infra_private_subnet_cidr # For SG rules (e.g., targeting IT Infra)

  ami_ubuntu_2204     = var.ami_ubuntu_2204 # Fallback
  ami_kali_linux      = var.ami_kali_linux  # Fallback
  ami_remnux          = var.ami_remnux      # Fallback (if REMnux instance is in Red Team)
  instance_type_docker_host = var.instance_type_docker_host
  instance_type_kali_remnux = var.instance_type_kali_remnux
  
  ssh_from_your_ip_sg_id = module.core_network.ssh_from_your_ip_sg_id
  it_infra_inbound_from_blue_red_sg_id = module.core_network.it_infra_inbound_from_blue_red_sg_id # To allow red team to hit IT infra
  # ... other SGs as needed
}
*/

# 4. Forensics Team Module
/*
module "forensics_team" {
  source                    = "./modules/forensics_team"
  project_name              = var.project_name
  aws_region                = var.aws_region
  key_pair_name             = var.key_pair_name
  your_public_ip            = var.your_public_ip
  vpc_id                    = module.core_network.vpc_id
  
  forensics_private_subnet_id = module.core_network.forensics_private_subnet_id

  ami_remnux                = var.ami_remnux # Fallback
  ami_flare_vm              = var.ami_flare_vm # Fallback
  instance_type_kali_remnux = var.instance_type_kali_remnux # Reusing type for REMnux
  instance_type_windows_workstation = var.instance_type_windows_workstation # For Flare VM
  
  ssh_from_your_ip_sg_id    = module.core_network.ssh_from_your_ip_sg_id
  rdp_from_your_ip_sg_id    = module.core_network.rdp_from_your_ip_sg_id # For Windows Flare VM
  # ... other SGs as needed
}
*/

# 5. IT Infrastructure Department Module
/*
module "it_infrastructure" {
  source              = "./modules/it_infrastructure"
  project_name        = var.project_name
  aws_region          = var.aws_region
  key_pair_name       = var.key_pair_name
  your_public_ip      = var.your_public_ip
  vpc_id              = module.core_network.vpc_id
  
  it_infra_private_subnet_id = module.core_network.it_infra_private_subnet_id

  blue_team_private_subnet_cidr = module.core_network.blue_team_private_subnet_cidr # For SG rules (allowing logs to SIEM)
  red_team_private_subnet_cidr  = module.core_network.red_team_private_subnet_cidr  # For SG rules (allowing attacks from Red Team)

  ami_windows_2019_base = var.ami_windows_2019_base # Fallback
  ami_windows_10_pro    = var.ami_windows_10_pro # Fallback
  ami_ubuntu_2204       = var.ami_ubuntu_2204 # For Docker host, fallback
  instance_type_windows_server = var.instance_type_windows_server
  instance_type_windows_workstation = var.instance_type_windows_workstation
  instance_type_docker_host = var.instance_type_docker_host
  
  ssh_from_your_ip_sg_id = module.core_network.ssh_from_your_ip_sg_id
  rdp_from_your_ip_sg_id = module.core_network.rdp_from_your_ip_sg_id
  it_infra_inbound_from_blue_red_sg_id = module.core_network.it_infra_inbound_from_blue_red_sg_id # To allow Blue/Red to hit IT infra
  # ... other SGs as needed
}
*/
