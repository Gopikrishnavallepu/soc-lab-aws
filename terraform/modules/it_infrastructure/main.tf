# terraform/modules/it_infrastructure/main.tf

# ---------------------------------------------------
# IT Infrastructure Department Module
# Deploys domain controller, workstations, generic server, and vulnerable web apps.
# ---------------------------------------------------

# --- Windows Server 2019 (Active Directory / DNS) ---
resource "aws_instance" "windows_server_2019" {
  ami           = var.ami_windows_2019_base
  instance_type = var.instance_type_windows_server # t3.medium
  subnet_id     = var.it_infra_private_subnet_id
  key_name      = var.key_pair_name # For RDP password decryption

  vpc_security_group_ids = [
    var.rdp_from_your_ip_sg_id,          # Allow RDP from your IP
    var.it_infra_inbound_from_blue_red_sg_id, # Allow Blue/Red team access
    # Add a specific SG for AD/DNS if not covered (e.g., ports 53, 88, 389, 445, 3389)
  ]

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
    encrypted   = true
  }

  # User data for basic AD installation (simplified)
  user_data = <<-EOF
    <powershell>
    Write-Host "Installing Active Directory Domain Services..." | Out-File C:\AD_install_log.txt
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    # This only installs the feature. You'll need to promote it to a domain controller manually
    # or use a more complex PowerShell script for full automation.
    Write-Host "AD DS feature installed. Promote to domain controller manually." | Out-File -Append C:\AD_install_log.txt

    # Install Wazuh agent (replace with actual download/install commands)
    Write-Host "Installing Wazuh agent..." | Out-File -Append C:\AD_install_log.txt
    # Example: Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.x.x.msi" -OutFile "C:\wazuh-agent.msi"
    # Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\wazuh-agent.msi /q WAZUH_MANAGER='<SECURITY_ONION_PRIVATE_IP>' WAZUH_AGENT_NAME='AD-Server'" -Wait
    # net start WazuhSvc

    # Install Sysmon
    Write-Host "Installing Sysmon..." | Out-File -Append C:\AD_install_log.txt
    # Example: Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "C:\Sysmon.zip"
    # Expand-Archive -Path C:\Sysmon.zip -DestinationPath C:\Sysmon
    # C:\Sysmon\Sysmon64.exe -accepteula -i C:\Sysmon\sysmonconfig.xml # You'll need to create sysmonconfig.xml
    </powershell>
  EOF

  tags = {
    Name    = "${var.project_name}-Windows-Server-AD"
    Project = var.project_name
    Role    = "IT-Infrastructure"
  }
}

# --- Windows 10 Workstations (Simulated Endpoints) ---
resource "aws_instance" "windows_10_workstation_1" {
  ami           = var.ami_windows_10_pro # <--- IMPORTANT: Replace with actual Windows 10 AMI
  instance_type = var.instance_type_windows_workstation # t3.medium
  subnet_id     = var.it_infra_private_subnet_id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    var.rdp_from_your_ip_sg_id,          # Allow RDP from your IP
    var.it_infra_inbound_from_blue_red_sg_id, # Allow Blue/Red team access
  ]

  root_block_device {
    volume_size = 150 # Windows 10 needs sufficient space
    volume_type = "gp2"
    encrypted   = true
  }

  user_data = <<-EOF
    <powershell>
    Write-Host "Windows 10 Workstation 1 launched. Remember to join domain, install Wazuh agent, Sysmon, and Atomic Red Team." | Out-File C:\workstation1_note.txt
    # Install Wazuh agent
    # Install Sysmon
    # Download/Install Atomic Red Team framework (e.g., Invoke-AtomicRedTeam)
    </powershell>
  EOF

  tags = {
    Name    = "${var.project_name}-Win10-Workstation-1"
    Project = var.project_name
    Role    = "IT-Infrastructure"
  }
}

resource "aws_instance" "windows_10_workstation_2" {
  ami           = var.ami_windows_10_pro # <--- IMPORTANT: Replace with actual Windows 10 AMI
  instance_type = var.instance_type_windows_workstation
  subnet_id     = var.it_infra_private_subnet_id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    var.rdp_from_your_ip_sg_id,
    var.it_infra_inbound_from_blue_red_sg_id,
  ]

  root_block_device {
    volume_size = 150
    volume_type = "gp2"
    encrypted   = true
  }

  user_data = <<-EOF
    <powershell>
    Write-Host "Windows 10 Workstation 2 launched. Remember to join domain, install Wazuh agent, Sysmon, and Atomic Red Team." | Out-File C:\workstation2_note.txt
    </powershell>
  EOF

  tags = {
    Name    = "${var.project_name}-Win10-Workstation-2"
    Project = var.project_name
    Role    = "IT-Infrastructure"
  }
}

# --- Linux Server (Generic) ---
resource "aws_instance" "linux_server" {
  ami           = var.ami_ubuntu_2204
  instance_type = "t3.micro" # Keep this small for low cost
  subnet_id     = var.it_infra_private_subnet_id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    var.ssh_from_your_ip_sg_id,          # Allow SSH from your IP
    var.it_infra_inbound_from_blue_red_sg_id, # Allow Blue/Red team access
  ]

  root_block_device {
    volume_size = 15
    volume_type = "gp2"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "Linux Server launched. Install Wazuh agent and other applications as needed." >> /var/log/linux_server_note.log
    apt-get update -y
    # Example: Install Nginx, Apache, or a custom vulnerable service here
    # Example: Install Wazuh agent
    # curl -Os https://packages.wazuh.com/4.x/linux/wazuh-agent-4.x.x-amd64.deb
    # dpkg -i ./wazuh-agent-4.x.x-amd64.deb
    # /var/ossec/bin/wazuh-agent-control -m <SECURITY_ONION_PRIVATE_IP>
    # systemctl daemon-reload
    # systemctl enable wazuh-agent
    # systemctl start wazuh-agent
  EOF

  tags = {
    Name    = "${var.project_name}-Linux-Server"
    Project = var.project_name
    Role    = "IT-Infrastructure"
  }
}

# --- IT Infrastructure Docker Host (Vulnerable Web Applications: DVWA/Metasploitable) ---
resource "aws_instance" "it_infra_docker_host" {
  ami           = var.ami_ubuntu_2204
  instance_type = var.instance_type_docker_host # t3.small or t3.medium
  subnet_id     = var.it_infra_private_subnet_id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    var.ssh_from_your_ip_sg_id,          # Allow SSH from your IP
    var.it_infra_inbound_from_blue_red_sg_id, # This SG will handle HTTP/HTTPS for DVWA from other subnets
  ]

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "Installing Docker and Docker Compose for IT Infra Docker Host..." >> /var/log/docker_setup.log
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu
    systemctl start docker
    systemctl enable docker
    echo "Docker and Docker Compose installed. Remember to deploy DVWA/Metasploitable using their docker-compose.yml files." >> /var/log/docker_setup.log

    # Example: You would scp your it_infra_apps_compose.yml file here and run it:
    # cd /home/ubuntu/
    # docker compose -f it_infra_apps_compose.yml up -d
  EOF

  tags = {
    Name    = "${var.project_name}-ITInfra-DockerHost"
    Project = var.project_name
    Role    = "IT-Infrastructure-Apps"
  }
}