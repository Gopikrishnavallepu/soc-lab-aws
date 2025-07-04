# **🛡️ SOC Home Lab on AWS: Automated Deployment**

This repository provides a robust and automated solution for deploying a Security Operations Center (SOC) home lab environment directly within your Amazon Web Services (AWS) account. Leveraging Terraform for Infrastructure as Code (IaC) and a Python automation script, this setup allows security enthusiasts, students, and professionals to build and experiment with blue team, red team, forensics, and IT infrastructure components in an isolated cloud environment.

Whether you're looking to practice threat hunting, incident response, penetration testing, or simply understand SOC operations, this lab provides a configurable foundation.

## **✨ Features**

- **Modular Deployment:** Deploy core network infrastructure and individual security teams (Blue, Red, Forensics, IT Infrastructure) independently or as needed.
- **Infrastructure as Code (IaC):** Full environment defined using Terraform, ensuring repeatability, version control, and consistency.
- **Python Automation:** A user-friendly Python script to simplify Terraform `init`, `apply`, and `destroy` operations, including intelligent commenting/uncommenting of modules in `main.tf`.
- **Core Network Foundation:** Configures VPC, subnets (public/private), NAT gateway, Internet Gateway, and essential security groups.
- **Blue Team Capabilities:** Deployment of Security Onion SIEM and a Docker host for tools like TheHive, Cortex, and MISP.
- **Red Team Capabilities:** Provisioning of Kali Linux, REMnux, and a Docker host for attack frameworks (e.g., Caldera, Covenant).
- **Forensics Workstation:** Setup for REMnux and Flare VM for malware analysis and digital forensics.
- **IT Infrastructure Simulation:** Deployment of Windows Server, Windows 10 Workstation(s), and a Docker host to simulate enterprise endpoints and servers, generating realistic logs.
- **Enhanced Logging:** Placeholder for endpoint logging (Sysmon, Atomic Red Team) to feed logs into the SIEM.

## **🏛️ Architecture Overview**

The lab is deployed within a dedicated AWS Virtual Private Cloud (VPC) to ensure network isolation. Resources are strategically placed across public and private subnets, with NAT Gateway providing outbound internet access for private instances.

### **Fixed Network Diagram (Text/ASCII Art)**

This diagram focuses on the logical network segmentation and key components to remain non-scrollable and easy to read.

```
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

```

### **Key Components**

- **Core Network Module:**
    - **VPC:** Isolated network space for the lab (`soc-lab-vpc`).
    - **Public Subnet (`10.10.0.0/24`):** Hosts the NAT instance, providing a secure egress point.
    - **Private Subnets:** Dedicated, isolated subnets for each team:
        - **Blue Team (`10.10.1.0/24`):** For defensive tools.
        - **Red** Team **(`10.10.2.0/24`):** For offensive tools.
        - **IT Infrastructure (`10.10.3.0/24`):** Simulates enterprise machines.
        - **Forensics (`10.10.4.0/24`):** For specialized analysis.
    - **NAT Instance/Gateway:** Provides outbound internet connectivity for instances in private subnets, enabling updates and external tool downloads without exposing them directly to the internet.
    - **Internet Gateway (IGW):** Connects the VPC to the public internet.
    - **Security Groups (SGs):** Fine-grained network access control. Includes rules for SSH/RDP from your public IP, and internal communication between departments.
- **Blue Team Module:**
    - **Security Onion SIEM:** A powerful open-source platform for network security monitoring, log management (Elasticsearch, Kibana), and threat hunting.
    - **Docker Host:** An Ubuntu instance running Docker, designed to host web-based security applications like TheHive (security incident response platform), Cortex (observable analysis engine), and MISP (Malware Information Sharing Platform).
- **Red Team Module:**
    - **Kali Linux:** A leading distribution for penetration testing and ethical hacking, packed with offensive tools.
    - **REMnux:** A specialized Linux distribution for reverse-engineering and malware analysis.
    - **Docker Host:** Configured to deploy red team attack frameworks such as Caldera or Covenant, providing command & control capabilities.
- **Forensics Module:**
    - **REMnux:** A dedicated instance for detailed digital forensics and malware analysis.
    - **Flare VM:** A Windows-based security distribution from Mandiant for malware analysis, leveraging tools like Ghidra, x64dbg, and other forensic utilities.
- **IT Infrastructure Module:**
    - **Windows Server 2019:** Simulates a typical enterprise domain controller or application server.
    - **Windows 10 Workstation(s):** Simulates end-user machines, acting as targets for red team operations and sources for security logs.
    - **Docker Host:** A general-purpose server, potentially running internal applications or services.
    - **Logging Agents:** (Placeholder configuration) Designed to install agents like Sysmon (for detailed Windows event logging) and potentially Atomic Red Team (for simulating attack techniques and generating telemetry) to create realistic log data.

### **Network Flow and Log Architecture**

The core idea is to create a realistic environment where logs are generated, collected, analyzed, and incidents can be managed.

1. **Log Generation (IT Infrastructure ➡️ Blue Team):**
    - Endpoints (Windows Server, Windows 10) in the **IT** Infrastructure Private Subnet generate various security logs (e.g., Windows Event Logs, Sysmon events, application logs).
    - These logs are configured to be securely forwarded (e.g., via Winlogbeat, Filebeat, or syslog) to the **Security Onion SIEM** instance.
    - Network traffic within the VPC can also be captured via VPC Flow Logs (a native AWS service, not explicitly managed by this Terraform, but highly recommended for network visibility) and potentially ingested by Security Onion.
2. **Log Ingestion & Analysis (Blue Team):**
    - The **Security Onion SIEM** (in the Blue Team Private Subnet) acts as the central log aggregator. It ingests the forwarded logs, parses them, enriches them with threat intelligence, and stores them in its Elasticsearch backend.
    - Security analysts access Security Onion's tools (Kibana, Hunting, Playbook) to perform threat hunting, review alerts, and conduct investigations.
3. **Threat Intelligence & Incident Response (Blue Team):**
    - The **Blue Team Docker Host** runs applications that support the blue team workflow:
        - **MISP:** For ingesting and sharing threat intelligence, enriching logs, and informing detection rules.
        - **TheHive/Cortex:** For managing security incidents, analyzing observables (IPs, domains, hashes) from alerts, and orchestrating response actions. Communication between Security Onion and TheHive/Cortex can be automated.
4. **Offensive Operations (Red Team ➡️ IT Infrastructure ➡️ Blue Team):**
    - Instances in the **Red Team Private Subnet** (Kali, Docker Host) are used to launch simulated attacks against targets within the **IT Infrastructure Private Subnet**.
    - These attacks generate security events and logs on the target IT Infrastructure machines.
    - These newly generated logs are then forwarded to the **Security Onion SIEM**, allowing the blue team to detect, investigate, and respond to the simulated attacks.
5. **Specialized Analysis (Forensics ➡️ Blue Team):**
    - When a suspicious file or artifact is discovered during blue team analysis, it can be securely transferred to the **Forensics Private Subnet** instances (REMnux, Flare VM) for deeper, isolated analysis (e.g., malware reverse engineering, disk imaging). This prevents contamination of the live lab environment.
6. **Inter-Department Communication (via Security Groups):**
    - **IT Infra to Blue Team:** Specific security group rules allow outbound log forwarding traffic from IT Infra machines to the Security Onion SIEM on designated ports (e.g., Logstash port).
    - **Red Team to IT Infra:** Security group rules allow offensive traffic (e.g., common attack ports like 22, 80, 443, 445) from Red Team IPs/subnets to IT Infra machines, simulating lateral movement and exploitation.
    - **Blue Team/Red Team/Forensics to Public Internet (via NAT):** Instances in these private subnets can reach the internet (for updates, tool downloads) via the NAT Gateway in the public subnet.
    - **Your** IP to Jump **Boxes/Management:** Specific security groups allow SSH/RDP from your defined public IP to management instances (e.g., the NAT Instance, or specific jump boxes) and then potentially internally.

## **🚀 Getting Started**

Follow these steps to set up and operate your SOC Home Lab on AWS.

### **Prerequisites**

Before you begin, ensure you have the following:

1. **AWS Account:** An active AWS account with sufficient permissions to create EC2 instances, VPCs, subnets, security groups, NAT Gateways, etc. (AdministratorAccess for simplicity during learning, but consider least privilege in production).
2. **AWS CLI Configured:** Your AWS CLI should be installed and configured with your AWS Access Key ID, Secret Access Key, and a default region.
    
    ```
    aws configure
    
    ```
    
3. **Terraform Installed:** Terraform (v1.0.0 or higher recommended) must be installed on your local machine and available in your system's PATH.
    
    ```
    terraform --version
    ```
    
4. **Python 3 Installed:** Python 3.x must be installed.
    
    ```
    python --version
    ```
    
5. **Python Dependencies:** Install the `colorama` library for colored terminal output:
    
    ```
    pip install colorama
    ```
    
6. **SSH Key Pair in AWS:** You need an SSH key pair imported into or created directly in your AWS region (e.g., `ap-south-1`).
    - **Name it `soc-lab-key` (or adjust `key_pair_name` in `main.py` if different).**
    - If you don't have one:
        
        ```
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/soc-lab-key
        ```
        
        Then, import `~/.ssh/soc-lab-key.pub` via AWS Console (EC2 -> Key Pairs -> Import key pair).
        
        - **Important:** Ensure the name you give it in the AWS console exactly matches what you set in the script (e.g., `soc-lab-key`).

### **Project Structure**

The project follows a modular Terraform structure, with a Python script to orchestrate deployments.

```
soc-lab-aws/
├── main.py                     # Python automation script for Terraform operations
└── terraform/                  # Root Terraform configuration directory
    ├── main.tf                 # Main orchestration file, calls modules
    ├── variables.tf            # Global variable declarations for the root module
    ├── outputs.tf              # Global output declarations
    ├── versions.tf             # Terraform and provider version constraints
    ├── providers.tf            # AWS Provider configuration
    ├── locals.tf               # Global local values
    ├── terraform.tfvars        # Default variable values (YOUR custom settings go here)
    ├── .gitignore              # Git ignore file (Crucial: to prevent committing .tfvars with sensitive info)
    └── modules/                # Reusable Terraform modules
        ├── core_network/       # VPC, subnets, NAT, IGW, core SGs
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── versions.tf
        ├── blue_team/          # Security Onion, Blue Team Docker Host
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── versions.tf
        ├── red_team/           # Kali, REMnux, Red Team Docker Host
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── versions.tf
        ├── forensics_team/     # REMnux, Flare VM
        │   ├── main.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── versions.tf
        └── it_infrastructure/  # Windows Server, Windows 10, IT Infra Docker Host
            ├── main.tf
            ├── variables.tf
            ├── outputs.tf
            └── versions.tf

```

### **Step-by-Step Deployment Process**

1. **Clone the Repository:**
    
    ```
    git clone https://github.com/your-username/soc-lab-aws.git
    cd soc-lab-aws
    
    ```
    
    *(Replace `https://github.com/your-username/soc-lab-aws.git` with your actual repository URL)*
    
2. **Configure Terraform Variables (`terraform/terraform.tfvars`):**
    - Navigate into the `terraform/` directory:
        
        ```
        cd terraform
        ```
        
    - Create a file named `terraform.tfvars` in this directory.
        
        ```
        # On Linux/macOS
        touch terraform.tfvars
        # On Windows
        notepad terraform.tfvars
        # or via VS Code / any IDE
        code terraform.tfvars
        
        ```
        
    - **Edit `terraform.tfvars`** and uncomment the lines (remove the `#` at the beginning of each line) and replace the placeholder values with your actual AWS configurations.
        
        ```
        # terraform.tfvars
        # This file provides default input variable values for your Terraform configuration.
        # DO NOT COMMIT SENSITIVE DATA (like private keys or passwords) TO PUBLIC GIT REPOSITORIES!
        
        project_name      = "SOCLab"
        aws_region        = "ap-south-1" # Or your desired AWS region (e.g., "us-east-1", "eu-west-2")
        key_pair_name     = "soc-lab-key" # IMPORTANT: Must exactly match the name of the SSH key pair you created/imported in your AWS account
        
        # IMPORTANT: Replace with YOUR ACTUAL PUBLIC IP + /32 CIDR (e.g., "203.0.113.45/32").
        # You can find your public IP by searching "What is my IP" on Google.
        # Using "0.0.0.0/0" is LESS SECURE as it allows SSH/RDP from anywhere,
        # but can be used for initial testing if you understand the risks.
        your_public_ip    = "YOUR_PUBLIC_IP/32"
        
        # Instance Types (adjust these based on your budget and performance needs)
        instance_type_nat           = "t3.small"
        instance_type_so            = "m5.large" # Security Onion can be resource-intensive
        instance_type_docker_host   = "t3.medium"
        instance_type_kali_remnux   = "t3.medium"
        instance_type_windows_server = "t3.large"
        instance_type_windows_workstation = "t3.medium"
        
        # AMI IDs (CRITICAL: Find current valid AMIs for your selected aws_region!)
        # You MUST replace these placeholder AMI IDs with actual, valid AMI IDs for your chosen region.
        # Invalid AMIs are a common cause of deployment failures.
        #
        # How to find AMIs:
        # 1. Go to AWS EC2 Console -> AMIs.
        # 2. Filter by "Public images" or "Owned by me" (if you've built custom AMIs).
        # 3. Search for the OS (e.g., "Ubuntu Server 22.04 LTS", "Windows_Server-2019-English-Full-Base", "kali-linux").
        #    Note: For Kali, REMnux, and Flare VM, you might need to subscribe via AWS Marketplace
        #    or search for community-contributed AMIs for your region, or even build your own.
        #    For Flare VM specifically, ensure the root volume size in `modules/forensics_team/main.tf`
        #    is sufficient (at least 150GB as discovered in previous debugging).
        ami_ubuntu_2204             = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual Ubuntu 22.04 AMI ID
        ami_kali_linux              = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual Kali Linux AMI ID
        ami_remnux                  = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual REMnux AMI ID
        ami_flare_vm                = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual Flare VM AMI ID
        ami_windows_2019_base       = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual Windows Server 2019 AMI ID
        ami_windows_10_pro          = "ami-xxxxxxxxxxxxxxxxx" # Example: Replace with actual Windows 10 Pro AMI ID
        
        ```
        
    - Save and close the `terraform.tfvars` file.
    - Add `terraform.tfvars` to your `.gitignore` file (if you haven't already in the root of your project) to prevent accidental commitment of your sensitive values:
        
        ```
        # .gitignore
        terraform.tfvars
        *.tfstate
        *.tfstate.*
        .terraform/
        
        ```
        
    - Return to the project root directory:
        
        ```
        cd ..
        
        ```
        
3. Run the Python Automation Script:
    
    Execute the Python script from the root of the cloned repository:
    
    ```
    python main.py
    
    ```
    
    You will be presented with an interactive menu.
    

### **Workflow of Python Script and Terraform**

The `main.py` script acts as an orchestrator for your Terraform deployments. Here's a breakdown of its workflow:

1. **Initialization and Menu Display:**
    - Upon execution, `main.py` initializes `colorama` for colored output.
    - It presents an interactive menu with options for various Terraform operations (init, plan, apply, destroy) and module management.
2. **`run_terraform_command` Function:**
    - This core function is called for most Terraform operations (`init`, `plan`, `apply`, `destroy`).
    - **Dynamic `main.tf` Modification:**
        - Before running any Terraform command, it reads the `terraform/main.tf` file.
        - Based on the chosen menu option, it dynamically comments out (`/* ... */`) or uncomments specific module blocks within `main.tf`. This is critical for `terraform apply -target` and `terraform destroy -target` to work correctly on individual modules.
        - For example, if you choose "Deploy Blue Team Operations," the script will uncomment the `module "blue_team"` block in `main.tf`.
    - **Variable Injection:** It dynamically constructs `var` flags for essential variables like `project_name`, `aws_region`, `key_pair_name`, and `your_public_ip`. These are passed directly to Terraform commands. Note that values from your `terraform.tfvars` will also be loaded automatically by Terraform.
    - **Terraform Execution:** It executes the specified Terraform command (e.g., `terraform apply -target=module.blue_team`) as a subprocess, streaming its output directly to your console for real-time feedback.
    - **Error Handling:** It captures Terraform's exit code and prints error messages if the command fails.
    - **`main.tf` Restoration (for non-state-changing commands):** For `init` and `plan` commands, the script attempts to restore `main.tf` to its original state after execution. For `apply` and `destroy`, `main.tf` is left reflecting the state of the deployed infrastructure.
3. **Module Management (Options 5 & 6):**
    - `manage_modules()`: This allows you to manually toggle the commented/uncommented state of individual module blocks in `main.tf`. This is useful if you want to explicitly enable or disable a module outside of the apply/destroy workflow, or prepare for custom Terraform runs.
    - `view_module_status()`: Displays the current comment status of each module in `main.tf`, helping you understand which parts of your lab are active.
4. **Deployment/Destruction Flow:**
    - **`Deploy Core Network` (Option 1):** The script uncomments the `core_network` module and runs `terraform init -reconfigure` followed by `terraform apply -auto-approve -target=module.core_network`. This establishes the fundamental networking infrastructure.
    - **`Deploy [Team] Operations` (Options 2-5):** For each team, the script first ensures the target module is uncommented in `main.tf`, then runs `terraform init -reconfigure`, and finally `terraform apply -auto-approve -target=module.[team_name]`.
    - **`Destroy [Team] Operations` (Options 6-9):** Similar to deployment, but runs `terraform destroy -auto-approve -target=module.[team_name]`. After destruction, it attempts to re-comment the module in `main.tf`.
    - **`Destroy Core Network` (Option 10):** First, all *optional* team modules are re-commented in `main.tf` to avoid issues. Then `terraform init -reconfigure` and `terraform destroy -auto-approve -target=module.core_network` are executed. This is a critical step, as it removes the core networking components, potentially breaking connectivity to any remaining instances.
    - **`Destroy ALL Resources` (Option 11 - CAUTION!):** This is the most destructive option. It prompts for explicit confirmation. If confirmed, it uncomments *all* modules in `main.tf`, runs `terraform init -reconfigure`, and then executes a global `terraform destroy -auto-approve` (without any targets) to tear down everything. Finally, it re-comments all optional modules in `main.tf`.

## **🔒 Security Considerations**

### **Pros**

- **Isolated Environment:** Deploying the lab within a dedicated AWS VPC provides strong network isolation from your production AWS resources and the broader internet.
- **Controlled Access:** Security Group rules are designed to limit SSH/RDP access primarily to your public IP, reducing exposure.
- **Learning Platform:** Provides a safe and disposable environment to practice offensive and defensive security techniques without impacting real systems.
- **Scalability & Elasticity:** Leverage AWS's cloud capabilities to easily scale resources up or down as needed for different lab scenarios.

### **Cons**

- **Cost:** Running EC2 instances, NAT Gateways, and EBS volumes incurs AWS costs. Monitor your AWS billing dashboard regularly and **destroy resources when not in use**.
- **Public IP Exposure:** The NAT instance and potentially other jump boxes might have public IPs. Ensure strict security group rules are in place.
- **Default Credentials/Hardening:** The deployed instances will likely have default configurations. It is crucial to implement proper security hardening (changing default passwords, applying patches, configuring host-based firewalls, etc.) for any long-running lab components.
- **AMI Security:** The security of your lab depends on the base AMIs you choose. Always select trusted, updated AMIs.
- **Log Forwarding Security:** Ensure secure protocols (e.g., TLS) are used for log forwarding to Security Onion.

## **✅ Pros and Cons of this Automation Approach**

### **Pros**

- **Streamlined Deployment:** Simplifies the complex multi-step process of deploying a full lab environment into a simple menu-driven interface.
- **Consistency:** Eliminates manual errors by automating Terraform commands.
- **Modularity:** Allows focused deployment/destruction of specific lab components without affecting others.
- **State Management:** Helps maintain a clean `main.tf` by dynamically commenting/uncommenting modules, reducing the risk of accidental deployments.

### **Cons**

- **File Modification:** The Python script modifies `main.tf` directly. While designed to be safe, any unexpected interruptions or manual edits during script execution could lead to `main.tf` being in an inconsistent state.
- **Dependency on Python:** Requires a Python environment and specific libraries (`colorama`).
- **Limited Error Context:** While error messages are displayed, debugging complex Terraform issues still requires understanding Terraform's output and potentially inspecting the state file manually.
- **No Parallelism:** The current script deploys/destroys modules sequentially.

## **🤝 Contribution Guide**

Contributions are welcome and highly encouraged! This project aims to be a comprehensive and user-friendly SOC home lab. Here are some areas where you can contribute:

- **Add More Tools/Modules:** Integrate other popular SOC tools (e.g., Wazuh, Elastic Stack, custom scripts, different C2 frameworks).
- **Improve Instance Provisioning:** Enhance `user_data` scripts for more automated tool installation and configuration (e.g., using Ansible/SaltStack for post-deployment configuration).
- **Advanced Logging Configuration:** Implement more robust log forwarding with specific configurations (e.g., Splunk Universal Forwarder, Elastic Agent).
- **Security Enhancements:** Propose and implement additional security best practices (e.g., IAM roles, KMS for encryption, network ACLs).
- **CI/CD Integration:** Develop pipelines for automated testing and deployment.
- **Documentation:** Improve existing documentation, add detailed guides for using specific tools within the lab.
- **Bug Fixes:** Identify and fix any bugs.

### **How to Contribute**

1. **Fork the Repository:** Start by forking this repository to your own GitHub account.
2. **Clone Your Fork:** Clone your forked repository to your local machine.
    
    ```
    git clone https://github.com/your-username/soc-lab-aws.git
    cd soc-lab-aws
    
    ```
    
3. **Create a New Branch:** Create a new branch for your feature or bug fix.
    
    ```
    git checkout -b feature/your-awesome-feature
    
    ```
    
4. **Make Changes:** Implement your changes.
5. **Test Your Changes:** Thoroughly test your modifications in your AWS account.
6. **Commit Your Changes:** Write clear and concise commit messages.
    
    ```
    git commit -m "feat: Add new awesome feature"
    
    ```
    
7. **Push to Your Fork:**
    
    ```
    git push origin feature/your-awesome-feature
    
    ```
    
8. **Open a Pull Request (PR):** Go to the original repository on GitHub and open a pull request from your branch to the `main` branch. Provide a detailed description of your changes.

## **⚠️ Disclaimer**

This project is intended for educational and lab purposes only. It is not designed for production environments. AWS services incur costs, and you are solely responsible for monitoring and managing your AWS usage to avoid unexpected charges. Always destroy resources when they are not in use. The author is not responsible for any costs incurred or security breaches that may occur from the use of this lab.

##
