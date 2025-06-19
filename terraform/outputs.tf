# terraform/outputs.tf

# Outputs to easily access key components of your SOC Lab

output "soc_lab_vpc_id" {
  description = "The ID of the main SOC Lab VPC."
  value       = module.core_network.vpc_id
}

output "nat_instance_public_ip" {
  description = "The Public IP address of the NAT Instance. You might use this as a jump box or to verify internet access."
  value       = module.core_network.nat_instance_public_ip
}

# Outputs from security groups now managed by core_network module
output "ssh_from_your_ip_sg_id" {
  value = module.core_network.ssh_from_your_ip_sg_id
  description = "ID of the Security Group allowing SSH from your public IP."
}
output "rdp_from_your_ip_sg_id" {
  value = module.core_network.rdp_from_your_ip_sg_id
  description = "ID of the Security Group allowing RDP from your public IP."
}
output "blue_team_inbound_logs_sg_id" {
  value = module.core_network.blue_team_inbound_logs_sg_id
  description = "ID of the Security Group allowing inbound logs to Blue Team."
}
output "it_infra_inbound_from_blue_red_sg_id" {
  value = module.core_network.it_infra_inbound_from_blue_red_sg_id
  description = "ID of the Security Group allowing inbound traffic from Blue/Red Team to IT Infra."
}