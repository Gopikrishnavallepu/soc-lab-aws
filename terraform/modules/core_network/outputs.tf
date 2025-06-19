# terraform/modules/core_network/outputs.tf

output "vpc_id" { value = aws_vpc.soc_lab_vpc.id }
output "public_subnet_id" { value = aws_subnet.public_subnet.id }
output "nat_instance_public_ip" { value = aws_instance.nat_instance.public_ip }
output "nat_instance_sg_id" { value = aws_security_group.nat_instance_sg.id }

output "blue_team_private_subnet_id" { value = aws_subnet.blue_team_private_subnet.id }
output "blue_team_private_subnet_cidr" { value = aws_subnet.blue_team_private_subnet.cidr_block }

output "red_team_private_subnet_id" { value = aws_subnet.red_team_private_subnet.id }
output "red_team_private_subnet_cidr" { value = aws_subnet.red_team_private_subnet.cidr_block }

output "forensics_private_subnet_id" { value = aws_subnet.forensics_private_subnet.id }
output "forensics_private_subnet_cidr" { value = aws_subnet.forensics_private_subnet.cidr_block }

output "it_infra_private_subnet_id" { value = aws_subnet.it_infra_private_subnet.id }
output "it_infra_private_subnet_cidr" { value = aws_subnet.it_infra_private_subnet.cidr_block }

# New Outputs for common Security Groups (moved from root security_groups.tf)
output "ssh_from_your_ip_sg_id" { value = aws_security_group.ssh_from_your_ip_sg.id }
output "rdp_from_your_ip_sg_id" { value = aws_security_group.rdp_from_your_ip_sg.id }
output "blue_team_inbound_logs_sg_id" { value = aws_security_group.blue_team_inbound_logs_sg.id }
output "it_infra_inbound_from_blue_red_sg_id" { value = aws_security_group.it_infra_inbound_from_blue_red_sg.id }