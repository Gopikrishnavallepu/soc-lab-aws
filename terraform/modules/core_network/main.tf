# terraform/modules/core_network/main.tf

# ---------------------------------------------------
# Core Network Infrastructure
# Sets up the VPC, subnets, Internet Gateway, NAT Instance, and VPC Peering.
# This module now also defines the common, reusable security groups.
# ---------------------------------------------------

# --- VPC (Virtual Private Cloud) ---
resource "aws_vpc" "soc_lab_vpc" {
  cidr_block           = "10.0.0.0/16" # Main CIDR block for your lab
  enable_dns_hostnames = true
  tags = {
    Name    = "${var.project_name}-VPC"
    Project = var.project_name
  }
}

# --- Internet Gateway (IGW) ---
# Allows communication between your VPC and the internet.
resource "aws_internet_gateway" "soc_lab_igw" {
  vpc_id = aws_vpc.soc_lab_vpc.id
  tags = {
    Name    = "${var.project_name}-IGW"
    Project = var.project_name
  }
}

# --- Public Subnet (for NAT Instance) ---
# Resources here have direct internet access via the IGW.
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.soc_lab_vpc.id
  cidr_block              = "10.0.0.0/24" # A /24 subnet within your VPC
  availability_zone       = "${var.aws_region}a" # Deploy in one AZ for simplicity
  map_public_ip_on_launch = true # Required for NAT Instance to get a public IP
  tags = {
    Name    = "${var.project_name}-Public-Subnet"
    Project = var.project_name
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.soc_lab_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.soc_lab_igw.id
  }
  tags = {
    Name    = "${var.project_name}-Public-RT"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# --- NAT Instance Configuration (Low-Cost Internet Egress) ---
# An EC2 instance acting as a Network Address Translator for private subnets.
resource "aws_security_group" "nat_instance_sg" {
  name        = "${var.project_name}-NAT-Instance-SG"
  description = "Security group for NAT Instance, allowing traffic from private subnets and SSH from your IP."
  vpc_id      = aws_vpc.soc_lab_vpc.id

  # Allow inbound SSH from your IP for management
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_public_ip]
    description = "Allow SSH from your public IP for NAT Instance management"
  }
  # Allow all traffic from private subnets to the NAT instance
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # List of all private subnet CIDRs that need NAT access
    cidr_blocks = [
      "10.0.1.0/24", # Blue Team
      "10.0.2.0/24", # Red Team
      "10.0.3.0/24", # Forensics Team
      "10.0.4.0/24"  # IT Infrastructure
    ]
    description = "Allow all traffic from private subnets to NAT instance"
  }

  # Allow all outbound traffic to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-NAT-Instance-SG"
  }
}

resource "aws_instance" "nat_instance" {
  ami             = var.ami_ubuntu_2204 # Using Ubuntu for the NAT Instance
  instance_type   = var.instance_type_nat
  subnet_id       = aws_subnet.public_subnet.id
  key_name        = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.nat_instance_sg.id]
  associate_public_ip_address = true # Give NAT instance a public IP

  # Disable source/destination check - CRITICAL for NAT instances to forward traffic
  source_dest_check = false

  # User data script to configure the EC2 instance as a NAT device
  user_data = <<-EOF
    #!/bin/bash
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    # Install iptables-persistent to save rules across reboots
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
    netfilter-persistent save
    netfilter-persistent reload
    echo "NAT Instance setup complete." > /var/log/nat_setup.log
  EOF

  tags = {
    Name    = "${var.project_name}-NAT-Instance"
    Project = var.project_name
  }
}

# --- Private Subnets for Each Department ---
# Resources in these subnets can only reach the internet via the NAT Instance.

# Blue Team Private Subnet
resource "aws_subnet" "blue_team_private_subnet" {
  vpc_id            = aws_vpc.soc_lab_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "${var.project_name}-BlueTeam-Private-Subnet" }
}
resource "aws_route_table" "blue_team_private_route_table" {
  vpc_id = aws_vpc.soc_lab_vpc.id
  tags = { Name = "${var.project_name}-BlueTeam-Private-RT" }
}
resource "aws_route_table_association" "blue_team_private_subnet_association" {
  subnet_id      = aws_subnet.blue_team_private_subnet.id
  route_table_id = aws_route_table.blue_team_private_route_table.id
}
# Route for Blue Team private subnet to the NAT instance
resource "aws_route" "blue_team_nat_route" {
  route_table_id         = aws_route_table.blue_team_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  # CORRECTED LINE BELOW:
  network_interface_id   = aws_instance.nat_instance.primary_network_interface_id
}


# Red Team Private Subnet
resource "aws_subnet" "red_team_private_subnet" {
  vpc_id            = aws_vpc.soc_lab_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "${var.project_name}-RedTeam-Private-Subnet" }
}
resource "aws_route_table" "red_team_private_route_table" {
  vpc_id = aws_vpc.soc_lab_vpc.id
  tags = { Name = "${var.project_name}-RedTeam-Private-RT" }
}
resource "aws_route_table_association" "red_team_private_subnet_association" {
  subnet_id      = aws_subnet.red_team_private_subnet.id
  route_table_id = aws_route_table.red_team_private_route_table.id
}
# Route for Red Team private subnet to the NAT instance
resource "aws_route" "red_team_nat_route" {
  route_table_id         = aws_route_table.red_team_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  # CORRECTED LINE BELOW:
  network_interface_id   = aws_instance.nat_instance.primary_network_interface_id
}

# Forensics Team Private Subnet
resource "aws_subnet" "forensics_private_subnet" {
  vpc_id            = aws_vpc.soc_lab_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "${var.project_name}-Forensics-Private-Subnet" }
}
resource "aws_route_table" "forensics_private_route_table" {
  vpc_id = aws_vpc.soc_lab_vpc.id
  tags = { Name = "${var.project_name}-Forensics-Private-RT" }
}
resource "aws_route_table_association" "forensics_private_subnet_association" {
  subnet_id      = aws_subnet.forensics_private_subnet.id
  route_table_id = aws_route_table.forensics_private_route_table.id
}
# Route for Forensics Team private subnet to the NAT instance
resource "aws_route" "forensics_nat_route" {
  route_table_id         = aws_route_table.forensics_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  # CORRECTED LINE BELOW:
  network_interface_id   = aws_instance.nat_instance.primary_network_interface_id
}

# IT Infrastructure Private Subnet
resource "aws_subnet" "it_infra_private_subnet" {
  vpc_id            = aws_vpc.soc_lab_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "${var.project_name}-ITInfra-Private-Subnet" }
}
resource "aws_route_table" "it_infra_private_route_table" {
  vpc_id = aws_vpc.soc_lab_vpc.id
  tags = { Name = "${var.project_name}-ITInfra-Private-RT" }
}
resource "aws_route_table_association" "it_infra_private_subnet_association" {
  subnet_id      = aws_subnet.it_infra_private_subnet.id
  route_table_id = aws_route_table.it_infra_private_route_table.id
}
# Route for IT Infrastructure private subnet to the NAT instance
resource "aws_route" "it_infra_nat_route" {
  route_table_id         = aws_route_table.it_infra_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  # CORRECTED LINE BELOW:
  network_interface_id   = aws_instance.nat_instance.primary_network_interface_id
}

# --- VPC Peering Connection (IT Infra <-> Blue Team for Log Collection) ---
# Allows private network communication between the IT Infra and Blue Team subnets.
# Find this block (likely around line 230 based on your error)
#resource "aws_vpc_peering_connection" "it_infra_to_blue_team_peering" {
  # Delete or comment out the entire block below:
  # vpc_id      = module.core_network.aws_vpc.soc_lab_vpc.id
  # peer_vpc_id = module.core_network.aws_vpc.soc_lab_vpc.id # This is the problem!
  # auto_accept = true # Or false, depending on intent
  # tags = {
  #   Name = "${var.project_name}-IT-Infra-to-Blue-Team-Peering"
  # }

# Add routes to route tables for VPC peering
# Find and DELETE or COMMENT OUT this entire block:
# resource "aws_route" "blue_team_to_it_infra_route" {
#   route_table_id            = aws_route_table.blue_team_private_route_table.id
#   destination_cidr_block    = var.it_infra_private_subnet_cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.it_infra_to_blue_team_peering.id
# }

# Find and DELETE or COMMENT OUT this entire block:
# resource "aws_route" "it_infra_to_blue_team_route" {
#   route_table_id            = aws_route_table.it_infra_private_route_table.id
#   destination_cidr_block    = var.blue_team_private_subnet_cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.it_infra_to_blue_team_peering.id
# }

# --- Common Access Security Groups (MOVED HERE from root security_groups.tf) ---

resource "aws_security_group" "ssh_from_your_ip_sg" {
  name        = "${var.project_name}-SSH-From-Your-IP-SG"
  description = "Allow SSH (Port 22) from your specific public IP address."
  vpc_id      = aws_vpc.soc_lab_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_public_ip]
    description = "Allow SSH from your local machine"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-SSH-Your-IP-SG" }
}

resource "aws_security_group" "rdp_from_your_ip_sg" {
  name        = "${var.project_name}-RDP-From-Your-IP-SG"
  description = "Allow RDP (Port 3389) from your specific public IP address."
  vpc_id      = aws_vpc.soc_lab_vpc.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.your_public_ip]
    description = "Allow RDP from your local machine"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-RDP-Your-IP-SG" }
}

resource "aws_security_group" "blue_team_inbound_logs_sg" {
  name        = "${var.project_name}-BlueTeam-Inbound-Logs-SG"
  description = "Allow Wazuh agent, Syslog, and other log sources from IT Infrastructure to Blue Team SIEM."
  vpc_id      = aws_vpc.soc_lab_vpc.id # Use this module's VPC ID

  # Wazuh Agent (TCP 1514, 1515)
  ingress {
    from_port   = 1514
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.it_infra_private_subnet.cidr_block] # Reference this module's subnets
    description = "Wazuh Agent from IT Infra"
  }
  # Syslog (UDP 514, TCP 601, 6514)
  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = [aws_subnet.it_infra_private_subnet.cidr_block]
    description = "Syslog UDP from IT Infra"
  }
  ingress {
    from_port   = 601
    to_port     = 6514
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.it_infra_private_subnet.cidr_block]
    description = "Syslog/TLS from IT Infra"
  }
  # Winlogbeat/Filebeat (TCP 5044) - if using direct Beats forwarding
  ingress {
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.it_infra_private_subnet.cidr_block]
    description = "Beats from IT Infra"
  }
  # Zeek/Suricata (if forwarding directly, or if SO is monitoring traffic)
  ingress {
    from_port   = 8080 # Example for SO Management UI (if needed from other internal hosts)
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.blue_team_private_subnet.cidr_block] # Internal access
    description = "SO Management UI from Blue Team subnet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-BlueTeam-Inbound-Logs-SG" }
}

resource "aws_security_group" "it_infra_inbound_from_blue_red_sg" {
  name        = "${var.project_name}-ITInfra-Inbound-BlueRed-SG"
  description = "Allow Red Team attacks and Blue Team management/collection to IT Infrastructure."
  vpc_id      = aws_vpc.soc_lab_vpc.id

  # Allow ALL traffic from Red Team subnet (for realistic attacks)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.red_team_private_subnet.cidr_block] # Reference this module's subnets
    description = "Allow all from Red Team subnet (attacks)"
  }

  # Allow Blue Team (e.g., WinRM for remote management/forensics, vulnerability scanning)
  ingress {
    from_port   = 5985 # WinRM (HTTP)
    to_port     = 5986 # WinRM (HTTPS)
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.blue_team_private_subnet.cidr_block]
    description = "Allow WinRM from Blue Team subnet"
  }
  ingress {
    from_port   = 135 # RPC (for some WinRM, WMI)
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.blue_team_private_subnet.cidr_block]
    description = "Allow RPC from Blue Team subnet"
  }
  ingress {
    from_port   = 445 # SMB (for file sharing, some WMI)
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.blue_team_private_subnet.cidr_block]
    description = "Allow SMB from Blue Team subnet"
  }
  # Add other ports for services on IT Infra (e.g., 80/443 for web apps)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.it_infra_private_subnet.cidr_block, aws_subnet.red_team_private_subnet.cidr_block, aws_subnet.blue_team_private_subnet.cidr_block]
    description = "Allow HTTP to IT Infra Docker Host (DVWA)"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.it_infra_private_subnet.cidr_block, aws_subnet.red_team_private_subnet.cidr_block, aws_subnet.blue_team_private_subnet.cidr_block]
    description = "Allow HTTPS to IT Infra Docker Host"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ITInfra-Inbound-BlueRed-SG" }
}