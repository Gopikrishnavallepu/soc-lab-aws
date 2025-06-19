# terraform/modules/blue_team/main.tf

# ---------------------------------------------------
# Blue Team Operations Module
# Deploys Security Onion and a Docker host for analysis tools.
# ---------------------------------------------------

# --- Security Onion SIEM ---
# Dedicated instance for Security Onion due to its resource requirements.
resource "aws_instance" "security_onion_server" {
  ami           = var.ami_ubuntu_2204 # Use a robust Linux AMI or dedicated SO AMI
  instance_type = var.instance_type_so # e.g., m5.large, t3.xlarge
  subnet_id     = var.blue_team_private_subnet_id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    var.ssh_from_your_ip_sg_id,          # Allow SSH from your IP
    var.blue_team_inbound_logs_sg_id,    # Allow inbound logs from IT Infra
    # Add a specific SG if you need to expose SO UI to specific IPs/ranges internally
  ]

  # Root volume for OS and SO installation
  root_block_device {
    volume_size = 50 # Minimum 50GB for SO OS partition
    volume_type = "gp2"
    encrypted   = true
  }
  # Additional volume for Elasticsearch data (logs)
  ebs_block_device {
    device_name = "/dev/sdf" # Standard device name for data volume
    volume_size = 100 # Start with 100GB, increase as needed (logs can grow fast)
    volume_type = "gp2"
    encrypted   = true
    delete_on_termination = true
  }

  # User data to run initial setup scripts on the instance
  # This is a placeholder. Security Onion installation is complex and often interactive.
  # You might manually install or use a pre-built Security Onion AMI.
  user_data = <<-EOF
    #!/bin/bash
    echo "Starting Security Onion placeholder setup..." >> /var/log/so_setup.log
    apt-get update -y
    # Basic dependencies for SO (you'd follow SO's official installation guide)
    # For a full automated setup, you'd integrate official SO installer commands here.
    echo "Security Onion requires manual installation or a dedicated AMI for full setup." >> /var/log/so_setup.log
    echo "Please refer to Security Onion documentation for installation steps." >> /var/log/so_setup.log
    # Example: wget -qO - https://docs.securityonion.net/ | bash /dev/stdin --silent
    # Then, 'sudo so-setup' will guide you through configuration.
    # Alternatively, find a pre-built Security Onion AMI in the AWS Marketplace.
  EOF

  tags = {
    Name    = "${var.project_name}-SecurityOnion-SIEM"
    Project = var.project_name
    Role    = "BlueTeam"
  }
}

# --- Blue Team Docker Host (TheHive, Cortex, MISP) ---
# A single instance to run multiple analysis tools as Docker containers.
resource "aws_instance" "blue_team_docker_host" {
  ami           = var.ami_ubuntu_2204
  instance_type = var.instance_type_docker_host # t3.small or t3.medium
  subnet_id     = var.blue_team_private_subnet_id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    var.ssh_from_your_ip_sg_id, # Allow SSH from your IP for management
    # Add SG rules for TheHive/Cortex/MISP web UIs (e.g., from your jump box or internal Blue Team IPs)
    # You would typically access these via SSH tunneling or an internal jump box, not publicly.
    aws_security_group.blue_team_docker_app_sg.id
  ]

  root_block_device {
    volume_size = 30 # Sufficient for OS and Docker images
    volume_type = "gp2"
    encrypted   = true
  }

  # User data to install Docker and Docker Compose
  user_data = <<-EOF
    #!/bin/bash
    echo "Installing Docker and Docker Compose..." >> /var/log/docker_setup.log
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu
    systemctl start docker
    systemctl enable docker
    echo "Docker and Docker Compose installed. Remember to deploy TheHive, Cortex, MISP using docker-compose.yml files." >> /var/log/docker_setup.log

    # Example: You would scp your docker-compose.yml file here and run it:
    # Example for TheHive, Cortex, MISP (assuming you've copied blue_team_apps_compose.yml)
    # cd /home/ubuntu/
    # docker compose -f blue_team_apps_compose.yml up -d
  EOF

  tags = {
    Name    = "${var.project_name}-BlueTeam-DockerHost"
    Project = var.project_name
    Role    = "BlueTeam-Apps"
  }
}

# Security Group for Docker Host applications (TheHive, Cortex, MISP UIs)
resource "aws_security_group" "blue_team_docker_app_sg" {
  name        = "${var.project_name}-BlueTeam-Docker-App-SG"
  description = "Allow internal access to TheHive, Cortex, MISP web UIs."
  vpc_id      = var.vpc_id

  # Inbound: Allow internal network access to TheHive, Cortex, MISP ports
  ingress {
    from_port   = 9000 # TheHive default port
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.blue_team_private_subnet_cidr] # Allow from own subnet
    description = "TheHive UI"
  }
  ingress {
    from_port   = 9001 # Cortex default port
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = [var.blue_team_private_subnet_cidr]
    description = "Cortex API"
  }
  ingress {
    from_port   = 8080 # MISP default HTTP (if configured)
    to_port     = 8443 # MISP default HTTPS
    protocol    = "tcp"
    cidr_blocks = [var.blue_team_private_subnet_cidr]
    description = "MISP UI"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-BlueTeam-Docker-App-SG" }
}