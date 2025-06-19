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

