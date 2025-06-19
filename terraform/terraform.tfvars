# # terraform.tfvars
# # This file provides default input variable values for your Terraform configuration.
# # DO NOT COMMIT SENSITIVE DATA (like private keys or passwords) TO PUBLIC GIT REPOSITORIES!
#
# project_name      = "SOCLab"
# aws_region        = "ap-south-1" # Or your desired AWS region (e.g., "us-east-1", "eu-west-2")
# key_pair_name     = "soc-lab-key" # IMPORTANT: Must exactly match the name of the SSH key pair you created/imported in your AWS account
#
# # IMPORTANT: Replace with YOUR ACTUAL PUBLIC IP + /32 CIDR (e.g., "203.0.113.45/32").
# # You can find your public IP by searching "What is my IP" on Google.
# # Using "0.0.0.0/0" is LESS SECURE as it allows SSH/RDP from anywhere,
# # but can be used for initial testing if you understand the risks.
# your_public_ip    = "YOUR_PUBLIC_IP/32"
#
# # Instance Types (adjust these based on your budget and performance needs)
# instance_type_nat           = "t3.small"
# instance_type_so            = "m5.large" # Security Onion can be resource-intensive
# instance_type_docker_host   = "t3.medium"
# instance_type_kali_remnux   = "t3.medium"
# instance_type_windows_server = "t3.large"
# instance_type_windows_workstation = "t3.medium"
#
# # AMI IDs (CRITICAL: Find current valid AMIs for your selected aws_region!)
# # You MUST replace these placeholder AMI IDs with actual, valid AMI IDs for your chosen region.
# # Invalid AMIs are a common cause of deployment failures.
# #
# # How to find AMIs:
# # 1. Go to AWS EC2 Console -> AMIs.
# # 2. Filter by "Public images" or "Owned by me" (if you've built custom AMIs).
# # 3. Search for the OS (e.g., "Ubuntu Server 22.04 LTS", "Windows_Server-2019-English-Full-Base", "kali-linux").
# #    Note: For Kali, REMnux, and Flare VM, you might need to subscribe via AWS Marketplace
# #    or search for community-contributed AMIs for your region, or even build your own.
# #    For Flare VM specifically, ensure the root volume size in `modules/forensics_team/main.tf`
# #    is sufficient (at least 150GB as discovered in previous debugging).
# ami_ubuntu_2204             = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual Ubuntu 22.04 AMI ID
# ami_kali_linux              = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual Kali Linux AMI ID
# ami_remnux                  = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual REMnux AMI ID
# ami_flare_vm                = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual Flare VM AMI ID
# ami_windows_2019_base       = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual Windows Server 2019 AMI ID
# ami_windows_10_pro          = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual Windows 10 Pro AMI ID