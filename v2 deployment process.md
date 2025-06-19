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

+-------------------------------------------------+
| AWS VPC (soc-lab-vpc - 10.10.0.0/16)            |
|                                                 |
|  +----------------------+  +------------------+ |
|  | Public Subnet        |--| Internet Gateway | |
|  | (10.10.0.0/24)       |  +------------------+ |
|  |   +-------------+    |                       |
|  |   | NAT Instance|----| NAT Gateway          |
|  |   +-------------+    | (Outbound Internet)  |
|  +----------------------+  +------------------+ |
|                                                 |
|  +-------------------------------------------+  |
|  | Private Subnets (Internal Segments)       |  |
|  |                                           |  |
|  |  +-----------------------+                |  |
|  |  | Blue Team (10.10.1.0/24) |              |  |
|  |  |   - Security Onion      |              |  |
|  |  |   - Docker Host         |              |  |
|  |  +----------^--------------+              |  |
|  |             |                              |  |
|  |  +----------V--------------+              |  |
|  |  | Red Team (10.10.2.0/24) |              |  |
|  |  |   - Kali Linux          |              |  |
|  |  |   - Docker Host         |              |  |
|  |  +----------^--------------+              |  |
|  |             |                              |  |
|  |  +----------V--------------+              |  |
|  |  | IT Infra (10.10.3.0/24) |              |  |
|  |  |   - Win Server 2019     |              |  |
|  |  |   - Win 10 Workstation  |              |  |
|  |  +----------^--------------+              |  |
|  |             |                              |  |
|  |  +----------V--------------+              |  |
|  |  | Forensics (10.10.4.0/24)|              |  |
|  |  |   - REMnux              |              |  |
|  |  |   - Flare VM            |              |  |
|  |  +-----------------------+                |  |
|  +-------------------------------------------+  |
+-------------------------------------------------+


### Key Components

* **Core Network Module:**
    * **VPC:** Isolated network space for the lab (`soc-lab-vpc`).
    * **Public Subnet (`10.10.0.0/24`):** Hosts the NAT instance, providing a secure egress point.
    * **Private Subnets:** Dedicated, isolated subnets for each team:
        * **Blue Team (`10.10.1.0/24`):** For defensive tools.
        * **Red Team (`10.10.2.0/24`):** For offensive tools.
        * **IT Infrastructure (`10.10.3.0/24`):** Simulates enterprise machines.
        * **Forensics (`10.10.4.0/24`):** For specialized analysis.
    * **NAT Instance/Gateway:** Provides outbound internet connectivity for instances in private subnets, enabling updates and external tool downloads without exposing them directly to the internet.
    * **Internet Gateway (IGW):** Connects the VPC to the public internet.
    * **Security Groups (SGs):** Fine-grained network access control. Includes rules for SSH/RDP from your public IP, and internal communication between departments.

* **Blue Team Module:**
    * **Security Onion SIEM:** A powerful open-source platform for network security monitoring, log management (Elasticsearch, Kibana), and threat hunting.
    * **Docker Host:** An Ubuntu instance running Docker, designed to host web-based security applications like TheHive (security incident response platform), Cortex (observable analysis engine), and MISP (Malware Information Sharing Platform).

* **Red Team Module:**
    * **Kali Linux:** A leading distribution for penetration testing and ethical hacking, packed with offensive tools.
    * **REMnux:** A specialized Linux distribution for reverse-engineering and malware analysis.
    * **Docker Host:** Configured to deploy red team attack frameworks such as Caldera or Covenant, providing command & control capabilities.

* **Forensics Module:**
    * **REMnux:** A dedicated instance for detailed digital forensics and malware analysis.
    * **Flare VM:** A Windows-based security distribution from Mandiant for malware analysis, leveraging tools like Ghidra, x64dbg, and other forensic utilities.

* **IT Infrastructure Module:**
    * **Windows Server 2019:** Simulates a typical enterprise domain controller or application server.
    * **Windows 10 Workstation(s):** Simulates end-user machines, acting as targets for red team operations and sources for security logs.
    * **Docker Host:** A general-purpose server, potentially running internal applications or services.
    * **Logging Agents:** (Placeholder configuration) Designed to install agents like Sysmon (for detailed Windows event logging) and potentially Atomic Red Team (for simulating attack techniques and generating telemetry) to create realistic log data.

### Network Flow and Log Architecture

The core idea is to create a realistic environment where logs are generated, collected, analyzed, and incidents can be managed.

1.  **Log Generation (IT Infrastructure ➡️ Blue Team):**
    * Endpoints (Windows Server, Windows 10) in the **IT Infrastructure Private Subnet** generate various security logs (e.g., Windows Event Logs, Sysmon events, application logs).
    * These logs are configured to be securely forwarded (e.g., via Winlogbeat, Filebeat, or syslog) to the **Security Onion SIEM** instance.
    * Network traffic within the VPC can also be captured via VPC Flow Logs (a native AWS service, not explicitly managed by this Terraform, but highly recommended for network visibility) and potentially ingested by Security Onion.

2.  **Log Ingestion & Analysis (Blue Team):**
    * The **Security Onion SIEM** (in the Blue Team Private Subnet) acts as the central log aggregator. It ingests the forwarded logs, parses them, enriches them with threat intelligence, and stores them in its Elasticsearch backend.
    * Security analysts access Security Onion's tools (Kibana, Hunting, Playbook) to perform threat hunting, review alerts, and conduct investigations.

3.  **Threat Intelligence & Incident Response (Blue Team):**
    * The **Blue Team Docker Host** runs applications that support the blue team workflow:
        * **MISP:** For ingesting and sharing threat intelligence, enriching logs, and informing detection rules.
        * **TheHive/Cortex:** For managing security incidents, analyzing observables (IPs, domains, hashes) from alerts, and orchestrating response actions. Communication between Security Onion and TheHive/Cortex can be automated.

4.  **Offensive Operations (Red Team ➡️ IT Infrastructure ➡️ Blue Team):**
    * Instances in the **Red Team Private Subnet** (Kali, Docker Host) are used to launch simulated attacks against targets within the **IT Infrastructure Private Subnet**.
    * These attacks generate security events and logs on the target IT Infrastructure machines.
    * These newly generated logs are then forwarded to the **Security Onion SIEM**, allowing the blue team to detect, investigate, and respond to the simulated attacks.

5.  **Specialized Analysis (Forensics ➡️ Blue Team):**
    * When a suspicious file or artifact is discovered during blue team analysis, it can be securely transferred to the **Forensics Private Subnet** instances (REMnux, Flare VM) for deeper, isolated analysis (e.g., malware reverse engineering, disk imaging). This prevents contamination of the live lab environment.

6.  **Inter-Department Communication (via Security Groups):**
    * **IT Infra to Blue Team:** Specific security group rules allow outbound log forwarding traffic from IT Infra machines to the Security Onion SIEM on designated ports (e.g., Logstash port).
    * **Red Team to IT Infra:** Security group rules allow offensive traffic (e.g., common attack ports like 22, 80, 443, 445) from Red Team IPs/subnets to IT Infra machines, simulating lateral movement and exploitation.
    * **Blue Team/Red Team/Forensics to Public Internet (via NAT):** Instances in these private subnets can reach the internet (for updates, tool downloads) via the NAT Gateway in the public subnet.
    * **Your IP to Jump Boxes/Management:** Specific security groups allow SSH/RDP from your defined public IP to management instances (e.g., the NAT Instance, or specific jump boxes) and then potentially internally.

## 🚀 Getting Started

Follow these steps to set up and operate your SOC Home Lab on AWS.

### Prerequisites

Before you begin, ensure you have the following:

1.  **AWS Account:** An active AWS account with sufficient permissions to create EC2 instances, VPCs, subnets, security groups, NAT Gateways, etc. (AdministratorAccess for simplicity during learning, but consider least privilege in production).
2.  **AWS CLI Configured:** Your AWS CLI should be installed and configured with your AWS Access Key ID, Secret Access Key, and a default region.
    ```bash
    aws configure
    ```
3.  **Terraform Installed:** Terraform (v1.0.0 or higher recommended) must be installed on your local machine and available in your system's PATH.
    ```bash
    terraform --version
    ```
4.  **Python 3 Installed:** Python 3.x must be installed.
    ```bash
    python --version
    ```
5.  **Python Dependencies:** Install the `colorama` library for colored terminal output:
    ```bash
    pip install colorama boto3
    ```
6.  **SSH Key Pair in AWS:** You need an SSH key pair imported into or created directly in your AWS region (e.g., `ap-south-1`).
    * **Name it `soc-lab-key` (or adjust `key_pair_name` in `main.py` if different).**
    * If you don't have one:
        ```bash
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/soc-lab-key
        ```
        Then, import `~/.ssh/soc-lab-key.pub` via AWS Console (EC2 -> Key Pairs -> Import key pair).
        * **Important:** Ensure the name you give it in the AWS console exactly matches what you set in the script (e.g., `soc-lab-key`).

### Project Structure (Version 2)

soc-lab-aws-v2/
├── main.py                     # Python automation script for Terraform operations (V2 with AMI management)
└── terraform/                  # Root Terraform configuration directory
├── main.tf                 # Main orchestration file, calls modules (UPDATED for V2 AMI logic)
├── variables.tf            # Global variable declarations for the root module
├── outputs.tf              # Global output declarations
├── versions.tf             # Terraform and provider version constraints
├── providers.tf            # AWS Provider configuration
├── locals.tf               # Global local values
├── terraform.tfvars        # Default variable values (YOUR custom settings go here)
├── custom_amis.json        # NEW: Stores captured custom AMI IDs (Managed by main.py)
├── .gitignore              # UPDATED: Add custom_amis.json to ignore list
└── modules/                # Reusable Terraform modules
├── core_network/       # VPC, subnets, NAT, IGW, core SGs
│   ├── main.tf         # (UPDATED for V2 AMI logic - see note below)
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── blue_team/          # Security Onion, Blue Team Docker Host
│   ├── main.tf         # (UPDATED for V2 AMI logic)
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── red_team/           # Kali, REMnux, Red Team Docker Host
│   ├── main.tf         # (UPDATED for V2 AMI logic)
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── forensics_team/     # REMnux, Flare VM
│   ├── main.tf         # (UPDATED for V2 AMI logic)
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
└── it_infrastructure/  # Windows Server, Windows 10, IT Infra Docker Host
├── main.tf         # (UPDATED for V2 AMI logic)
├── variables.tf
├── outputs.tf
└── versions.tf




### Step-by-Step Deployment Process (Version 2)

This workflow is divided into two main phases: a one-time initial setup to create your custom AMIs, and then the rapid, repeatable deployments.

#### Phase A: Initial Lab Deployment & Configuration (One-time Setup to Create Golden AMIs)

This phase needs to be done *once* for each significant version of your configured lab.

1.  **Preparation (within `soc-lab-aws-v2/`):**
    * **Edit `soc-lab-aws-v2/terraform/terraform.tfvars`:**
        * Set your `ami_ubuntu_2204`, `ami_kali_linux`, `ami_windows_2019_base`, etc., variables to the **public, unconfigured base AMI IDs** from the AWS Marketplace or official sources. These are your starting points.
        * Ensure `your_public_ip` and `key_pair_name` are correctly set.
    * **Ensure `soc-lab-aws-v2/terraform/custom_amis.json` is empty `{}`.** (If it exists with old data, empty it for this fresh start).
    * Make sure `boto3` is installed (`pip install boto3`).
    * Navigate to the `soc-lab-aws-v2/` directory: `cd /path/to/soc-lab-aws-v2/`

2.  **Deploy the Base Lab (using `main.py`):**
    * Run `python main.py`.
    * Select `1` (Initialize Terraform).
    * Select `5` (Manage Specific Modules).
    * Enable **ALL** the modules by entering `1 2 3 4 5` and then `done`. This ensures all your desired VMs are part of the next `apply`.
    * Return to the main menu and select `3` (Apply Deployment).
    * Review the Terraform plan. **This will create new EC2 instances based on your *base AMIs***. Type `yes` to confirm.
    * **Wait for deployment to complete.** This might take some time as it's pulling fresh AMIs.

3.  **Configure Software Inside Running EC2 Instances (Crucial Manual Step):**
    * Go to your AWS EC2 Console. Wait for all instances to be in `running` state.
    * **Connect to each instance via SSH or RDP** using the `key_pair_name` you provided and your `your_public_ip`.
    * **Perform all necessary software installations and configurations:**
        * **Security Onion Instance:** SSH in. Run `sudo so-setup`, configure it as a `STANDALONE` deployment, choose your network interfaces, configure storage (`/nsm`), create admin users, and ensure web UI is accessible. (This is the most time-consuming part).
        * **Kali Linux Instance:** SSH in. Update packages (`sudo apt update && sudo apt upgrade`). Install any additional penetration testing tools you prefer. Configure your shell.
        * **REMnux Instance:** SSH in. Update (`sudo remnux-update`).
        * **Flare VM Instance:** RDP in. Ensure it's fully updated and configured. This often involves Windows Updates and verifying Flare VM's tools are installed.
        * **Windows Server/Workstation Instances:** RDP in. Install any enterprise applications you want to simulate. Install and configure log forwarding agents (e.g., Sysmon, Winlogbeat, or NXLog) to send logs to the Security Onion instance's *private IP address* (on the Blue Team Internal Network).
        * **Docker Host Instances (Blue Team, Red Team, IT Infra):** SSH in. Install Docker and Docker Compose. Pull down base images for the tools you intend to run (e.g., TheHive, Cortex, MISP for Blue Team Docker Host; Caldera, Covenant for Red Team Docker Host).
    * **Thoroughly test connectivity and log flow** between relevant lab components.

4.  **Capture Custom AMIs from Configured Instances (New Feature in `main.py`):**
    * With your configured instances still `running` in AWS, return to your `python main.py` script.
    * Select `7` (Capture Custom AMIs from Running Instances).
    * The script will list your running `SOCLab` instances.
    * It will prompt you to select which instances to snapshot. You can enter individual numbers (e.g., `1 3 5`) or type `all`.
    * The script will initiate the AMI creation process for each selected instance. **This can take significant time (10-30+ minutes per AMI)** as AWS needs to create snapshots of the root volumes. **Do NOT terminate instances during this process.**
    * Upon completion, the script will show the new AMI IDs and automatically update your `soc-lab-aws-v2/terraform/custom_amis.json` file.
    * **Important:** The AMI captures the *root volume only*. If you have a separate `/nsm` data volume for Security Onion, its data won't be part of the AMI. For `/nsm` data persistence, you would need to manage its EBS snapshot separately and restore it to a *new* EBS volume attached to the launched SO instance (more advanced, usually done for persistent data stores, not for ephemeral labs). For a fresh lab session, starting with a clean `/nsm` is often desired.

5.  **Destroy the Initially Deployed Lab:**
    * After the AMIs are successfully created and `custom_amis.json` is updated, return to the `main.py` menu.
    * Select `4` (Destroy Deployment). This will terminate all the currently running EC2 instances and associated resources.
    * Confirm `yes`. This is essential to stop incurring high compute costs.

#### Phase B: Rapid Deployment using Custom AMIs (Repeatedly, Faster)

From now on, when you want to use the lab, you'll follow this quick deployment process.

1.  **Run `python main.py`.**
2.  **Select `1` (Initialize Terraform).** (Always a good habit before `plan`/`apply`).
3.  **Select `5` (Manage Specific Modules):** Enable only the modules you need for this particular lab session (e.g., `1` for core, `2` for Blue Team, `5` for IT Infra). Type `done`.
4.  **Select `3` (Apply Deployment):**
    * Terraform will now read `custom_amis.json` (which was updated in Phase A).
    * It will launch new EC2 instances directly from your pre-configured custom AMIs.
    * **Observe the speed!** This step should be significantly faster (minutes vs. hours) as no in-guest configuration is being performed.
    * Confirm `yes`.
5.  **Lab Ready:** Your lab is now ready to use with all software pre-installed and configured!

#### Phase C: Clean Up (Cost Saving)

When you're finished with a lab session, **destroy the resources to avoid incurring continuous AWS costs.**

1.  **Run `python main.py`.**
2.  **Select `4` (Destroy Deployment):** This will terminate all the currently running EC2 instances and associated resources.
    * Confirm `yes`.
3.  **(Optional) Destroy Specific Modules:** If you only deployed certain modules, you can use `5` to disable them first, then `4` to destroy just those.

## 🔒 Security Considerations

### Pros

* **Isolated Environment:** Deploying the lab within a dedicated AWS VPC provides strong network isolation from your production AWS resources and the broader internet.
* **Controlled Access:** Security Group rules are designed to limit SSH/RDP access primarily to your public IP, reducing exposure.
* **Learning Platform:** Provides a safe and disposable environment to practice offensive and defensive security techniques without impacting real systems.
* **Scalability & Elasticity:** Leverage AWS's cloud capabilities to easily scale resources up or down as needed for different lab scenarios.

### Cons

* **Cost:** Running EC2 instances, NAT Gateways, and EBS volumes incurs AWS costs. Monitor your AWS billing dashboard regularly and **destroy resources when not in use**.
* **Public IP Exposure:** The NAT instance and potentially other jump boxes might have public IPs. Ensure strict security group rules are in place.
* **Default Credentials/Hardening:** The deployed instances will likely have default configurations. It is crucial to implement proper security hardening (changing default passwords, applying patches, configuring host-based firewalls, etc.) for any long-running lab components.
* **AMI Security:** The security of your lab depends on the base AMIs you choose. Always select trusted, updated AMIs.
* **Log Forwarding Security:** Ensure secure protocols (e.g., TLS) are used for log forwarding to Security Onion.

## ✅ Pros and Cons of this Automation Approach

### Pros

* **Streamlined Deployment:** Simplifies the complex multi-step process of deploying a full lab environment into a simple menu-driven interface.
* **Consistency:** Eliminates manual errors by automating Terraform commands.
* **Modularity:** Allows focused deployment/destruction of specific lab components without affecting others.
* **State Management:** Helps maintain a clean `main.tf` by dynamically commenting/uncommenting modules, reducing the risk of accidental deployments.

### Cons

* **File Modification:** The Python script modifies `main.tf` directly. While designed to be safe, any unexpected interruptions or manual edits during script execution could lead to `main.tf` being in an inconsistent state.
* **Dependency on Python:** Requires a Python environment and specific libraries (`colorama`).
* **Limited Error Context:** While error messages are displayed, debugging complex Terraform issues still requires understanding Terraform's output and potentially inspecting the state file manually.
* **No Parallelism:** The current script deploys/destroys modules sequentially.

## 🤝 Contribution Guide

Contributions are welcome and highly encouraged! This project aims to be a comprehensive and user-friendly SOC home lab. Here are some areas where you can contribute:

* **Add More Tools/Modules:** Integrate other popular SOC tools (e.g., Wazuh, Elastic Stack, custom scripts, different C2 frameworks).
* **Improve Instance Provisioning:** Enhance `user_data` scripts for more automated tool installation and configuration (e.g., using Ansible/SaltStack for post-deployment configuration).
* **Advanced Logging Configuration:** Implement more robust log forwarding with specific configurations (e.g., Splunk Universal Forwarder, Elastic Agent).
* **Security Enhancements:** Propose and implement additional security best practices (e.g., IAM roles, KMS for encryption, network ACLs).
* **CI/CD Integration:** Develop pipelines for automated testing and deployment.
* **Documentation:** Improve existing documentation, add detailed guides for using specific tools within the lab.
* **Bug Fixes:** Identify and fix any bugs.

### How to Contribute

1.  **Fork the Repository:** Start by forking this repository to your own GitHub account.

2.  **Clone Your Fork:** Clone your forked repository to your local machine.

    ```bash
    git clone [https://github.com/your-username/soc-lab-aws.git](https://github.com/your-username/soc-lab-aws.git)
    cd soc-lab-aws
    ```

3.  **Create a New Branch:** Create a new branch for your feature or bug fix.

    ```bash
    git checkout -b feature/your-awesome-feature
    ```

4.  **Make Changes:** Implement your changes.

5.  **Test Your Changes:** Thoroughly test your modifications in your AWS account.

6.  **Commit Your Changes:** Write clear and concise commit messages.

    ```bash
    git commit -m "feat: Add new awesome feature"
    ```

7.  **Push to Your Fork:**

    ```bash
    git push origin feature/your-awesome-feature
    ```

8.  **Open a Pull Request (PR):** Go to the original repository on GitHub and open a pull request from your branch to the `main` branch. Provide a detailed description of your changes.

## ⚠️ Disclaimer

This project is intended for educational and lab purposes only. It is not designed for production environments. AWS services incur costs, and you are solely responsible for monitoring and managing your AWS usage to avoid unexpected charges. Always destroy resources when they are not in use. The author is not responsible for any costs incurred or security breaches that may occur from the use of this lab.

