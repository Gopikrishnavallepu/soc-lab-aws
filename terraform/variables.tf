# terraform/variables.tf

# ---------------------------------------------------
# Global Variables for SOC Lab
# ---------------------------------------------------

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1" # Match this with providers.tf and your aws configure
}

variable "project_name" {
  description = "A common prefix/tag for all resources to identify them easily."
  type        = string
  default     = "SOCLab"
}

variable "key_pair_name" {
  description = "The name of the AWS EC2 Key Pair to use for SSH access to Linux instances. Make sure this key pair exists in your AWS account and you have the .pem file!"
  type        = string
  default     = "soc-lab-key" # <--- IMPORTANT: Change this to YOUR actual key pair name!
}

variable "your_public_ip" {
  description = "Your local public IP address in CIDR format (e.g., 203.0.113.45/32) for secure SSH/RDP access. Use 'curl ifconfig.me' or a website like 'whatsmyip.org' to find it. Set to '0.0.0.0/0' ONLY for testing (NOT RECOMMENDED for production)."
  type        = string
  default     = "0.0.0.0/0" # <--- IMPORTANT: CHANGE THIS TO YOUR ACTUAL PUBLIC IP FOR SECURITY! e.g., "1.2.3.4/32"
}

# ---------------------------------------------------
# AMI (Amazon Machine Image) IDs
# Find the latest appropriate AMI IDs for your chosen AWS region!
# You can search in the EC2 Console -> AMIs or use AWS CLI.
# ---------------------------------------------------

variable "ami_ubuntu_2204" {
  description = "AMI ID for Ubuntu Server 22.04 LTS (HVM, SSD Volume Type). Used for NAT Instance, Docker Hosts, Linux Server, Security Onion."
  type        = string
  default     = "ami-021a584b49225376d" # Example for us-east-1 (Ubuntu Server 22.04 LTS), VERIFY LATEST!
}

variable "ami_windows_2019_base" {
  description = "AMI ID for Windows Server 2019 Base. Used for AD Server."
  type        = string
  default     = "ami-0c47b14fff9e56d8e" # Example for us-east-1, VERIFY LATEST!
}

variable "ami_windows_10_pro" {
  description = "AMI ID for Windows 10 Pro (often available via AWS Marketplace or custom import). If not, you might need to use Windows Server with Desktop Experience and simulate workstations."
  type        = string
  default     = "ami-000213a60381824ca" # <--- IMPORTANT: YOU LIKELY NEED TO FIND/IMPORT/CREATE THIS! Placeholder.
}

variable "ami_kali_linux" {
  description = "AMI ID for Kali Linux (Check Offensive Security's official AMIs or AWS Marketplace for your region)."
  type        = string
  default     = "ami-052793c032018fa8a" # <--- IMPORTANT: YOU NEED TO FIND THIS! Placeholder.
}

variable "ami_remnux" {
  description = "AMI ID for REMnux (Check REMnux official docs for cloud deployment, or use Ubuntu base and install manually)."
  type        = string
  default     = "ami-0103d782ccfc0dce0" # <--- IMPORTANT: YOU NEED TO FIND THIS! Placeholder.
}

variable "ami_flare_vm" {
  description = "AMI ID for Flare VM (Typically built on a Windows Server/Desktop AMI, or requires manual installation after launching a Windows instance). Use a Windows Server with Desktop Experience if no direct Flare VM AMI."
  type        = string
  default     = "ami-000213a60381824ca" # <--- IMPORTANT: YOU NEED TO FIND THIS (likely a Windows base) Placeholder.
}

# ---------------------------------------------------
# Instance Types (Cost Optimization)
# t3.micro is free-tier eligible (with limits).
# Choose smallest type that meets performance.
# ---------------------------------------------------

variable "instance_type_nat" {
  description = "Instance type for the NAT Instance (t3.micro is cheapest)."
  type        = string
  default     = "t3.micro"
}

variable "instance_type_so" {
  description = "Instance type for Security Onion (requires significant resources)."
  type        = string
  default     = "m5.large" # m5.large or t3.xlarge recommended for better performance
}

variable "instance_type_docker_host" {
  description = "Instance type for Linux Docker Hosts (Blue, Red, IT Infra). Balances cost and performance for multiple containers."
  type        = string
  default     = "t3.small" # Can try t3.micro for extremely low cost, but might struggle.
}

variable "instance_type_kali_remnux" {
  description = "Instance type for Kali and REMnux VMs (interactive use needs some CPU/RAM)."
  type        = string
  default     = "t3.medium"
}

variable "instance_type_windows_server" {
  description = "Instance type for Windows Server VMs (AD Server)."
  type        = string
  default     = "t3.medium" # Windows instances are generally more resource-intensive.
}

variable "instance_type_windows_workstation" {
  description = "Instance type for Windows 10 Workstation VMs and Flare VM."
  type        = string
  default     = "t3.medium" # Windows instances are generally more resource-intensive.
}