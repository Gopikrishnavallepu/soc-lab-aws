# Example: soc-lab-aws-v2/terraform/modules/blue_team/main.tf

# Locals block to read custom_amis.json for dynamic AMI selection
locals {
  # Path to custom_amis.json from the root terraform directory
  # `path.root` refers to the root of the Terraform configuration (`terraform/` folder)
  custom_amis_file_path = "${path.root}/custom_amis.json"
  # Read the JSON file if it exists, otherwise initialize as an empty map
  custom_amis = fileexists(local.custom_amis_file_path) ? jsondecode(file(local.custom_amis_file_path)) : {}
}

resource "aws_instance" "security_onion" {
  # ... existing resource configurations ...

  # New AMI selection logic:
  # Try to use a custom AMI from custom_amis.json first.
  # If 'security_onion_ami_id' key does not exist in custom_amis.json,
  # fall back to the default 'ami_ubuntu_2204' provided via variables.tf.
  ami           = try(local.custom_amis.security_onion_ami_id, var.ami_ubuntu_2204)
  instance_type = var.instance_type_so
  key_name      = var.key_pair_name
  subnet_id     = var.blue_team_private_subnet_id
  vpc_security_group_ids = [
    var.ssh_from_your_ip_sg_id,
    var.blue_team_inbound_logs_sg_id,
    # ... other SGs
  ]
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-SecurityOnion" # IMPORTANT: This tag 'Name' is used by Python script
  })
  # user_data = file("scripts/security_onion_setup.sh") # Keep this if you use it for initial setup
}

resource "aws_instance" "blue_team_docker_host" {
  # ... existing resource configurations ...
  ami           = try(local.custom_amis.blue_team_docker_host_ami_id, var.ami_ubuntu_2204)
  instance_type = var.instance_type_docker_host
  key_name      = var.key_pair_name
  subnet_id     = var.blue_team_private_subnet_id
  vpc_security_group_ids = [
    var.ssh_from_your_ip_sg_id,
    # ... other SGs
  ]
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-BlueTeam-DockerHost" # IMPORTANT: This tag 'Name' is used by Python script
  })
}
