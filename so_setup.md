You're asking for a very practical and powerful optimization for your SOC Home Lab! The process involves launching a Security Onion instance from the AWS Marketplace, manually configuring it to your exact needs, then capturing that configured state as your own custom AMI. This "golden AMI" can then be used by your Terraform scripts for super-fast, repeatable deployments in your `ap-south-1` region, saving you significant time and cost.

Here's a detailed, step-by-step guide on how to achieve this, focusing on the configuration within the AWS console and the Security Onion setup.

---

## 🧅 Creating and Utilizing Your Custom Security Onion AMI on AWS (Version 2)

The goal here is to create a fully configured Security Onion machine in AWS, turn it into your own custom Amazon Machine Image (AMI), and then use that AMI for all future rapid deployments of your SOC Lab. This bypasses the lengthy initial setup phase every time you spin up the lab.

**Assumptions:**
* You have an active AWS account.
* You have a VPC and at least one public and one private subnet configured in your `ap-south-1` (Mumbai) region (as per your existing Terraform setup).
* Your SSH key pair (e.g., `soc-lab-key`) is already imported into AWS and you have the `.pem` file locally.
* You are working within the `soc-lab-aws-v2` project directory as per our previous discussion.
* You have installed `boto3` for the Python script (`pip install boto3`).

### Phase 1: Initial Deployment & Configuration of a "Golden" Security Onion Instance

In this phase, we launch a Security Onion instance from the AWS Marketplace, configure it fully, and prepare it for AMI creation.

#### Step 1.1: Prepare AWS Security Groups

You'll need specific Security Groups (SGs) to control access to your Security Onion instance.

1.  **Navigate to EC2 Dashboard:** Go to the AWS Management Console, search for "EC2", and open the dashboard.
2.  **Go to Security Groups:** In the left-hand navigation pane, under "Network & Security", click **Security Groups**.
3.  **Create "Security Onion Management" Security Group:**
    * Click **Create security group**.
    * **Basic Details:**
        * **Security group name:** `SOCLab-SecurityOnion-Management-SG`
        * **Description:** `Allows SSH and HTTPS for Security Onion management.`
        * **VPC:** Select your lab's VPC (e.g., `soc-lab-vpc` from your Terraform setup).
    * **Inbound Rules:**
        * Click **Add rule**.
        * **Type:** `SSH`, **Source:** `Custom`, enter `your_public_ip/32` (your home/office public IP).
        * **Type:** `HTTPS`, **Source:** `Custom`, enter `your_public_ip/32`.
        * **Type:** `Custom TCP`, **Port range:** `5044` (for Filebeat/Winlogbeat logs), **Source:** `Custom`, enter the CIDR of your IT Infrastructure Private Subnet (e.g., `10.10.3.0/24`). This allows your Windows VMs to send logs.
        * **Type:** `Custom UDP`, **Port range:** `514` (for Syslog), **Source:** `Custom`, enter the CIDR of your IT Infrastructure Private Subnet (e.g., `10.10.3.0/24`).
    * **Outbound Rules:**
        * (Default: All traffic, `0.0.0.0/0`) This is usually fine for outbound internet access for updates.
    * Click **Create security group**.

4.  **Create "Security Onion Sniffing" Security Group:**
    * Click **Create security group**.
    * **Basic Details:**
        * **Security group name:** `SOCLab-SecurityOnion-Sniffing-SG`
        * **Description:** `Allows all inbound traffic for Security Onion sniffing interface.`
        * **VPC:** Select your lab's VPC.
    * **Inbound Rules:**
        * Click **Add rule**.
        * **Type:** `All traffic`, **Source:** `Custom`, enter the CIDR blocks of all subnets you want to mirror traffic *from* (e.g., your Red Team Private Subnet `10.10.2.0/24`, IT Infrastructure Private Subnet `10.10.3.0/24`). This must be as open as possible for sniffing.
    * **Outbound Rules:** (Default: All traffic, `0.0.0.0/0`)
    * Click **Create security group**.

#### Step 1.2: Create a Dedicated Sniffing Network Interface

Security Onion Sensors need a dedicated network interface for sniffing mirrored traffic.

1.  **Navigate to Network Interfaces:** In the EC2 Dashboard, under "Network & Security", click **Network Interfaces**.
2.  **Create Network Interface:**
    * Click **Create network interface**.
    * **Description:** `SOCLab Security Onion Sniffing Interface`
    * **Subnet:** Choose the **same private subnet** where you plan to launch your Security Onion instance (e.g., your Blue Team Private Subnet: `10.10.1.0/24`).
    * **Security groups:** Select the `SOCLab-SecurityOnion-Sniffing-SG` you just created.
    * Click **Create network interface**.
    * **Note down its Network Interface ID** (e.g., `eni-0abcdef1234567890`). You'll need this when launching the EC2 instance.

#### Step 1.3: Launch Security Onion EC2 Instance from Marketplace

Now, let's launch the instance that will become your golden AMI.

1.  **Launch Instance:** From the EC2 Dashboard, click **Launch Instances**.
2.  **Name:** `SOCLab-SecurityOnion-GoldenAMI-Temp` (This instance is temporary, used only for configuration).
3.  **Application and OS Images (AMI):**
    * Click **Browse more AMIs**.
    * Go to **AWS Marketplace AMIs**.
    * In the search bar, type `Security Onion` and press Enter.
    * Select the **official Security Onion Community Edition AMI** published by "Security Onion Solutions, LLC".
    * Click **Continue**.
4.  **Instance type:** Based on the requirements you provided, let's choose for a `Standalone` setup.
    * **Type:** `t3a.2xlarge` (for "Evaluation")
    * **Or:** `t3a.xlarge` (for "Standalone Production" - lower volume). For a lab, `t3a.xlarge` is often sufficient.
5.  **Key pair (login):** Select your existing `soc-lab-key` (or whatever you named it).
6.  **Network settings:**
    * **VPC:** Select your `soc-lab-vpc`.
    * **Subnet:** Select your **Blue Team Private Subnet** (e.g., `10.10.1.0/24`).
    * **Auto-assign Public IP:** **Disable** (since it's in a private subnet, outbound internet will use NAT Gateway).
    * **Firewall (Security Groups):** Select `SOCLab-SecurityOnion-Management-SG`.
    * **Advanced Network Configuration:** This is where you attach the sniffing interface.
        * Under "Network interfaces", you'll see `eth0` (the management interface).
        * Click **Add network interface**.
        * For the **Network interface** dropdown, select the **Sniffing Network Interface ID** you created in Step 1.2 (e.g., `eni-0abcdef1234567890`). This will become `eth1` inside the VM.
7.  **Configure storage:**
    * **Root Volume (`/dev/sda1` for Linux):** Increase size to **at least 256 GB** (or your preferred size for the OS and initial tooling). Set type to `gp3` (recommended for cost/performance).
    * **Add new volume:** Click **Add new volume**.
        * **Size:** **256 GB** (or more, based on your data needs for `/nsm`).
        * **Volume Type:** `gp3`.
        * **Device Name:** Note this (e.g., `/dev/sdh` or `/dev/xvdf`). This will be your `/nsm` partition.
8.  **Advanced details:** (Optional) You can leave these as default unless you have specific needs.
9.  **Launch instance.**

#### Step 1.4: Connect to the Instance and Run Security Onion Setup (`so-setup`)

This is where you fully configure Security Onion inside the running EC2 instance.

1.  **Wait for Instance to be Running:** In the EC2 Dashboard -> Instances, wait for your `SOCLab-SecurityOnion-GoldenAMI-Temp` instance to show "Running" and pass 2/2 status checks.
2.  **SSH into the instance:**
    * Find the instance's **Private IP address**.
    * You'll likely need to SSH to a bastion host or a jump box in your public subnet first, then from there SSH into the Security Onion instance.
    * The default username for the Security Onion AMI is **`onion`**.
    ```bash
    # From your local machine, if using a bastion host:
    # ssh -i /path/to/soc-lab-key.pem ubuntu@<BASTION_HOST_PUBLIC_IP>
    # From bastion host to Security Onion:
    ssh -i /path/to/soc-lab-key.pem onion@<SECURITY_ONION_PRIVATE_IP>
    ```
    * (If you placed SO in a public subnet for testing: `ssh -i /path/to/soc-lab-key.pem onion@<SECURITY_ONION_PUBLIC_IP>`)

3.  **Run `sudo so-setup` (Interactive Setup):**
    Once logged in, the `so-setup` script might start automatically. If not, run:
    ```bash
    sudo so-setup
    ```
    Follow the prompts carefully. Key choices:
    * **Install Type:**
        * For a simple lab that does everything on one machine: Choose **`STANDALONE`**.
        * If you plan a multi-node grid (manager, sensor, search nodes): Select the appropriate role (e.g., `MANAGER`, `SENSOR`). The provided documentation refers to this.
    * **Network Interfaces:**
        * **Management Interface:** Select `eth0`.
        * **Monitoring Interface:** Select `eth1` (this is your sniffing interface created in Step 1.2).
    * **Storage Configuration:**
        * Security Onion will detect your second EBS volume. Follow the prompts to configure it as the `/nsm` partition. This is crucial for storing logs and Elasticsearch data.
    * **User Creation:** Create a user for accessing the Security Onion Console (SOC) web interface and set a strong password.
    * **Firewall:** Allow `so-setup` to configure the firewall based on your choices.
    * **NTP:** You can use AWS's built-in NTP server `169.254.169.123` or stick with `ntp.org` defaults.

    **Special Notes based on your provided info:**
    * **Ephemeral Storage:** If you were setting up a "Distributed Search Node" or "Evaluation" node *using Instance Storage* (e.g., `m5ad.xlarge`), you would SSH in, cancel `so-setup` if it auto-starts, run `sudo so-prepare-fs`, then re-run `sudo ./so-setup-network`. This is for *instance store* volumes, not EBS. For simplicity and data persistence, EBS (`gp3`) is generally preferred for labs unless high-volume capture is critical. Your chosen `t3a.xlarge` instance type primarily uses EBS, so `so-prepare-fs` might not be necessary.
    * **Manager Setup (if choosing `MANAGER` role):** When prompted for web access, selecting `other` and providing the instance's *private IP* is good for internal cluster communication. You can then access it from your management host using port forwarding or a bastion.
    * **`number_of_replicas` and ElastAlert 2:** These are advanced configurations for distributed grids. For a single-node lab, you generally don't need to adjust these.

4.  **Verify Security Onion Installation:**
    * After `so-setup` completes (it will take a long time and might reboot), access the Security Onion Console (SOC) web UI using `https://<Security_Onion_Private_IP>`.
    * Log in with the user you created.
    * Verify that all services are healthy (check the `sostatus` command in SSH and the SOC Health tab). Ensure dashboards (Kibana) are loading correctly.

#### Step 1.5 (Optional, but Recommended for Sensors): Configure AWS Traffic Mirroring

If you are setting up a dedicated "Sensor" node to monitor traffic from other parts of your VPC (e.g., your IT Infrastructure subnet), you need to configure traffic mirroring. The Security Onion instance launched above can be your "Sensor" (if you chose the `SENSOR` role during `so-setup`).

1.  **Create Mirror Target:**
    * Go to **VPC Dashboard** -> **Traffic Mirroring** -> **Mirror Targets**.
    * Click **Create traffic mirror target**.
    * **Description:** `SOCLab-SO-Sniffing-Target`
    * **Target type:** `Network Interface`
    * **Network Interface:** Select the **Sniffing Network Interface ID (eth1)** of your `SOCLab-SecurityOnion-GoldenAMI-Temp` instance (e.g., `eni-0abcdef1234567890`).
    * Click **Create**.

2.  **Create Mirror Filter:**
    * Go to **VPC Dashboard** -> **Traffic Mirroring** -> **Mirror Filters**.
    * Click **Create traffic mirror filter**.
    * **Description:** `SOCLab-Mirror-All-Traffic` (or specific filter rules for tuning)
    * **Inbound rules:** Add a rule, e.g., `All traffic` from `0.0.0.0/0`.
    * **Outbound rules:** Add a rule, e.g., `All traffic` from `0.0.0.0/0`.
    * Click **Create**.

3.  **Create Mirror Session:**
    * Go to **VPC Dashboard** -> **Traffic Mirroring** -> **Mirror Sessions**.
    * Click **Create traffic mirror session**.
    * **Description:** `SOCLab-IT-Infra-to-SO-Mirror`
    * **Mirror source:** Choose the **Network Interface ID of the instance you want to monitor** (e.g., the primary interface of your Windows Server or Windows Workstation in the IT Infrastructure subnet). **Note:** This instance *must* be an AWS Nitro-based instance type (most modern instance types are).
    * **Mirror target:** Select the `SOCLab-SO-Sniffing-Target` you created.
    * **Session number:** Enter `1` (or any unique number).
    * **Filter:** Select the `SOCLab-Mirror-All-Traffic` filter.
    * Click **Create**.

4.  **Verify Traffic Mirroring (on Security Onion Sensor):**
    * SSH into your `SOCLab-SecurityOnion-GoldenAMI-Temp` instance.
    * Run `sudo tcpdump -nni eth1` (assuming `eth1` is your sniffing interface). You should see traffic, possibly with VXLAN tagging.
    * Check Zeek logs: `ls -la /nsm/zeek/logs/current/` and `sudo tail -f /nsm/zeek/logs/current/*.log` to confirm logs are being generated.

### Phase 2: Capture Your Custom AMI

Once your Security Onion instance is fully configured and verified, capture its state as an AMI.

1.  **Ensure Instance is Running:** Your `SOCLab-SecurityOnion-GoldenAMI-Temp` instance must be in a `running` state.
2.  **Run Your Python Script (main.py):**
    * Navigate to your `soc-lab-aws-v2/` directory in your terminal.
    * Run `python main.py`.
    * **Select `7` (Capture Custom AMIs from Running Instances).**
    * The script will list running instances tagged with `Project=SOCLab`. Identify your `SOCLab-SecurityOnion-GoldenAMI-Temp` instance.
    * Enter its corresponding number (or `all`) to select it.
    * The script will initiate the `create-image` process. **This will take time (5-30+ minutes)** depending on the root volume size. The script will wait for it to complete.
    * **Do NOT terminate the instance until the AMI creation is 100% complete and verified.**
    * Once complete, the script will show the new AMI ID and automatically update your `soc-lab-aws-v2/terraform/custom_amis.json` file.
    * You can verify this by selecting `8` (View Current Custom AMI Mappings) in the `main.py` menu. You should see an entry like `"security_onion_ami_id": "ami-xxxxxxxxxxxxxxxxx"`.

### Phase 3: Destroy the Temporary Instance and Deploy from Your Custom AMI

Now that you have your golden AMI, you can destroy the temporary instance and use your faster deployment method.

1.  **Destroy the Temporary Golden AMI Instance:**
    * Go to your AWS EC2 Console -> Instances.
    * Select `SOCLab-SecurityOnion-GoldenAMI-Temp`.
    * Go to `Instance state` -> `Terminate instance`. Confirm.
    * This stops the billing for the running instance. The AMI (and its backing snapshot) will remain.

2.  **Update `terraform/terraform.tfvars` (Optional, but good practice):**
    * You can now update the `ami_ubuntu_2204` (or whatever `ami` variable Security Onion uses as a fallback in your `blue_team/main.tf` module) in `terraform/terraform.tfvars` to a generic, public Ubuntu AMI if it's not already. This variable will only be used if `custom_amis.json` doesn't have an entry for Security Onion.

3.  **Deploy the Security Onion Module (and others) using your custom AMI:**
    * Return to your `python main.py` script.
    * Select `1` (Initialize Terraform).
    * Select `5` (Manage Specific Modules).
    * Ensure `core_network` is enabled. Also, enable `blue_team` (and any other modules you want to deploy, like `it_infrastructure` if you want to mirror traffic). Type `done`.
    * Select `3` (Apply Deployment).
    * **Terraform will now use the custom AMI ID from `custom_amis.json` for Security Onion.** This deployment should be significantly faster as the instance launches with all software pre-installed.
    * Confirm `yes`.

You now have a pre-configured Security Onion instance deployed rapidly from your custom AMI! You can repeat Phase 3 (steps 2-3) anytime you need your lab, and only incur the cost of the running instances for the duration you use them. Remember to always destroy instances when you are finished.
