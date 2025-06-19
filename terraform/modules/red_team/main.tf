# terraform/modules/red_team/main.tf

# ---------------------------------------------------
# Red Team Operations Module
# Deploys a Docker host for CALDERA and a Kali Linux instance.
# ---------------------------------------------------

# --- Red Team Docker Host (CALDERA) ---
resource "aws_instance" "red_team_docker_host" {
  ami           = var.ami_ubuntu_2204
  instance_type = var.instance_type_docker_host # t3.small or t3.medium
  subnet_id     = var.red_team_private_subnet_id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    var.ssh_from_your_ip_sg_id,          # Allow SSH from your IP
    aws_security_group.caldera_app_sg.id, # Allow access to CALDERA UI/API
    # The it_infra_inbound_from_blue_red_sg_id will allow this host to attack IT Infra
  ]

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "Installing Docker and Docker Compose for Red Team Docker Host..." >> /var/log/docker_setup.log
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu
    systemctl start docker
    systemctl enable docker
    echo "Docker and Docker Compose installed. Remember to deploy CALDERA using its docker-compose.yml file." >> /var/log/docker_setup.log

    # Example: You would scp your caldera_compose.yml file here and run it:
    # cd /home/ubuntu/
    # docker compose -f caldera_compose.yml up -d
  EOF

  tags = {
    Name    = "${var.project_name}-RedTeam-DockerHost"
    Project = var.project_name
    Role    = "RedTeam-Apps"
  }
}

# Security Group for CALDERA application
resource "aws_security_group" "caldera_app_sg" {
  name        = "${var.project_name}-CALDERA-App-SG"
  description = "Allow access to CALDERA UI and agent communication."
  vpc_id      = var.vpc_id

  # Inbound: CALDERA UI and agent communication (usually 8888, 8889)
  ingress {
    from_port   = 8888 # CALDERA UI
    to_port     = 8889 # CALDERA Sandcat agent communication
    protocol    = "tcp"
    cidr_blocks = [var.red_team_private_subnet_cidr, var.your_public_ip] # Allow from own subnet and your IP (for management)
    description = "CALDERA UI & Agent"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound to internet (via NAT) and to IT Infra (via peering/routes)
  }

  tags = { Name = "${var.project_name}-CALDERA-App-SG" }
}

# --- Kali Linux VM ---
resource "aws_instance" "kali_linux_vm" {
  ami           = var.ami_kali_linux # <--- IMPORTANT: Replace with actual Kali AMI
  instance_type = var.instance_type_kali_remnux # e.g., t3.medium
  subnet_id     = var.red_team_private_subnet_id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    var.ssh_from_your_ip_sg_id, # Allow SSH from your IP
    # The it_infra_inbound_from_blue_red_sg_id will allow this host to attack IT Infra
  ]

  root_block_device {
    volume_size = 40 # Kali needs decent space
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name    = "${var.project_name}-KaliLinux-VM"
    Project = var.project_name
    Role    = "RedTeam"
  }
}