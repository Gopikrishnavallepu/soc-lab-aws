# 🛡️ SOC Home Lab on AWS: Automated Deployment

This repository provides a robust and automated solution for deploying a Security Operations Center (SOC) home lab environment directly within your Amazon Web Services (AWS) account. Leveraging Terraform for Infrastructure as Code (IaC) and a Python automation script, this setup allows security enthusiasts, students, and professionals to build and experiment with blue team, red team, forensics, and IT infrastructure components in an isolated cloud environment.

Whether you're looking to practice threat hunting, incident response, penetration testing, or simply understand SOC operations, this lab provides a configurable foundation.

## ✨ Features

* **Modular Deployment:** Deploy core network infrastructure and individual security teams (Blue, Red, Forensics, IT Infrastructure) independently or as needed.
* **Infrastructure as Code (IaC):** Full environment defined using Terraform, ensuring repeatability, version control, and consistency.
* **Python Automation:** A user-friendly Python script to simplify Terraform `init`, `apply`, and `destroy` operations, including intelligent commenting/uncommenting of modules in `main.tf`.
* **Core Network Foundation:** Configures VPC, subnets (public/private), NAT gateway, Internet Gateway, and essential security groups.
* **Blue Team Capabilities:** Deployment of Security Onion SIEM and a Docker host for tools like TheHive, Cortex, and MISP.
* **Red Team Capabilities:** Provisioning of Kali Linux, REMnux, and a Docker host for attack frameworks (e.g., Caldera, Covenant).
* **Forensics Workstation:** Setup for REMnux and Flare VM for malware analysis and digital forensics.
* **IT Infrastructure Simulation:** Deployment of Windows Server, Windows 10 Workstation(s), and a Docker host to simulate enterprise endpoints and servers, generating realistic logs.
* **Enhanced Logging:** Placeholder for endpoint logging (Sysmon, Atomic Red Team) to feed logs into the SIEM.

## 🏛️ Architecture Overview

The lab is deployed within a dedicated AWS Virtual Private Cloud (VPC) to ensure network isolation. Resources are strategically placed across public and private subnets, with NAT Gateway providing outbound internet access for private instances.

### Fixed Network Diagram (Text/ASCII Art)

This diagram focuses on the logical network segmentation and key components to remain non-scrollable and easy to read.
