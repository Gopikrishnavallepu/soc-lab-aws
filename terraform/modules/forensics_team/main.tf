# terraform/modules/forensics_team/main.tf

# ---------------------------------------------------
# Forensic Operations Module
# Deploys REMnux (Linux) and Flare VM (Windows) for malware analysis.
# ---------------------------------------------------

# --- REMnux VM ---
resource "aws_instance" "remnux_vm" {
  ami           = var.ami_remnux # <--- IMPORTANT: Replace with actual REMnux AMI
  instance_type = var.instance_type_kali_remnux # e.g., t3.medium
  subnet_id     = var.forensics_private_subnet_id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    var.ssh_from_your_ip_sg_id, # Allow SSH from your IP
    # Add any specific SGs needed for internal forensic tool communication
  ]

  root_block_device {
    volume_size = 40 # REMnux needs decent space
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name    = "${var.project_name}-REMnux-VM"
    Project = var.project_name
    Role    = "Forensics"
  }
}

# --- Flare VM ---
resource "aws_instance" "flare_vm" {
  ami           = var.ami_flare_vm # <--- IMPORTANT: Replace with a suitable Windows base AMI + manual Flare VM install if no direct AMI
  instance_type = var.instance_type_windows_workstation # e.g., t3.medium (Windows needs more resources)
  subnet_id     = var.forensics_private_subnet_id
  key_name      = var.key_pair_name # For Windows, this is used to decrypt the admin password

  vpc_security_group_ids = [
    var.rdp_from_your_ip_sg_id, # Allow RDP from your IP
    # Add any specific SGs needed for internal forensic tool communication
  ]

  root_block_device {
    volume_size = 150 # Flare VM (Windows) needs significant space
    volume_type = "gp2"
    encrypted   = true
  }
  # Or if it's an ebs_block_device (less likely for root, but check):
  # ebs_block_device {
  #   device_name = "/dev/sda1" # or similar
  #   volume_size = 80 # <--- THIS MIGHT ALSO BE THE LINE
  #   volume_type = "gp2"
  # }

  # User data example for Windows (simplified, typically for agent install or basic setup)
  user_data = <<-EOF
    <powershell>
    Write-Host "Flare VM base instance launched. Manual installation or custom AMI for Flare VM is recommended." | Out-File C:\flare_vm_note.txt
    # You would typically install the Flare VM tools manually here or use a custom AMI.
    </powershell>
  EOF

  tags = {
    Name    = "${var.project_name}-FlareVM"
    Project = var.project_name
    Role    = "Forensics"
  }
}