import os
import subprocess
import sys
import re
import json
import boto3
import time
from colorama import Fore, Style, init

# Initialize Colorama
init(autoreset=True)

TERRAFORM_DIR = "terraform"
MAIN_TF_PATH = os.path.join(TERRAFORM_DIR, "main.tf")
CUSTOM_AMIS_JSON_PATH = os.path.join(TERRAFORM_DIR, "custom_amis.json")

# Define modules that the Python script will manage in main.tf
# The keys here (1-5) correspond to the menu options for module management.
# ami_type_map: Maps a friendly instance name part (from instance tags) to the key used in custom_amis.json
MODULE_MAP = {
    "1": {"name": "core_network", "path_in_main_tf": "module \"core_network\""},
    "2": {"name": "blue_team", "path_in_main_tf": "module \"blue_team\"", "ami_type_map": {
        "securityonion": "security_onion_ami_id",
        "blueteam-dockerhost": "blue_team_docker_host_ami_id"
    }},
    "3": {"name": "red_team", "path_in_main_tf": "module \"red_team\"", "ami_type_map": {
        "kali-linux": "kali_linux_ami_id",
        "redteam-dockerhost": "red_team_docker_host_ami_id"
    }},
    "4": {"name": "forensics_team", "path_in_main_tf": "module \"forensics_team\"", "ami_type_map": {
        "remnux": "remnux_ami_id",
        "flarevm": "flare_vm_ami_id"
    }},
    "5": {"name": "it_infrastructure", "path_in_main_tf": "module \"it_infrastructure\"", "ami_type_map": {
        "windows-server": "windows_server_ami_id",
        "windows-workstation": "windows_workstation_ami_id",
        "itinfra-dockerhost": "it_infra_docker_host_ami_id"
    }},
}

def print_menu():
    """Displays the main menu options for the SOC Lab deployment script."""
    print(Fore.CYAN + "\n=== SOC Home Lab Deployment Menu (Version 2 - AMI Snapshots) ===")
    print(Fore.YELLOW + "1. Initialize Terraform (terraform init)")
    print(Fore.YELLOW + "2. Plan Deployment (terraform plan)")
    print(Fore.YELLOW + "3. Apply Deployment (terraform apply)")
    print(Fore.YELLOW + "4. Destroy Deployment (terraform destroy)")
    print(Fore.YELLOW + "5. Manage Specific Modules (Enable/Disable in main.tf)")
    print(Fore.YELLOW + "6. View Current Module Status")
    print(Fore.GREEN + "--- AMI Management (New in V2) ---")
    print(Fore.GREEN + "7. Capture Custom AMIs from Running Instances")
    print(Fore.GREEN + "8. View Current Custom AMI Mappings (custom_amis.json)")
    print(Fore.RED + "9. Exit")
    print(Style.RESET_ALL)

def run_terraform_command(command, modules_to_enable=None, prompt_approval=True):
    """
    Runs a Terraform command in the TERRAFORM_DIR.
    Handles enabling/disabling modules in main.tf before execution.
    :param command: The Terraform command to run (e.g., "init", "apply", "destroy").
    :param modules_to_enable: A list of module names (strings) to ensure are uncommented.
                              If None, the script will not modify main.tf content dynamically.
                              If [], all non-core modules will be commented.
    :param prompt_approval: If True, `terraform apply/destroy` will prompt for approval. If False, `-auto-approve` is used.
    :return: True if the Terraform command succeeded, False otherwise.
    """
    print(Fore.BLUE + f"\nExecuting: terraform {command} in {TERRAFORM_DIR}/")

    if not os.path.exists(MAIN_TF_PATH):
        print(Fore.RED + f"Error: {MAIN_TF_PATH} not found. Please ensure the 'terraform' directory and 'main.tf' exist.")
        return False

    original_content = ""
    try:
        with open(MAIN_TF_PATH, 'r') as f:
            original_content = f.read()

        temp_content = original_content

        # Only modify main.tf if `modules_to_enable` is explicitly provided
        if modules_to_enable is not None:
            for key, module_info in MODULE_MAP.items():
                module_name = module_info["name"]
                # This regex captures the module block including surrounding comments (/* ... */)
                pattern = r"(\/\*)?\s*(module\s*\"" + re.escape(module_name) + r"\"\s*\{[\s\S]*?\})(\s*\*\/)?"
                match = re.search(pattern, temp_content)

                if match:
                    full_module_block = match.group(0) # The entire matched string including comments if present
                    module_code = match.group(2)     # Just the module { ... } part

                    if module_name in modules_to_enable:
                        # If target is enabled, ensure it's uncommented
                        if full_module_block.strip().startswith("/*") and full_module_block.strip().endswith("*/"):
                            print(Fore.GREEN + f"Uncommenting module: {module_name}")
                            temp_content = temp_content.replace(full_module_block, module_code.strip()) # strip extra whitespace
                    else:
                        # If target is disabled, ensure it's commented
                        if not (full_module_block.strip().startswith("/*") and full_module_block.strip().endswith("*/")):
                            print(Fore.YELLOW + f"Commenting out module: {module_name}")
                            temp_content = temp_content.replace(full_module_block, f"/*\n{module_code.strip()}\n*/")
                else:
                    # Core network might not be explicitly commented, so don't warn if its not found
                    if module_name != "core_network":
                        print(Fore.YELLOW + f"Warning: Module '{module_name}' not found in {MAIN_TF_PATH}. Cannot modify its comment status.")

            # Write the modified content to main.tf
            with open(MAIN_TF_PATH, 'w') as f:
                f.write(temp_content)

        full_cmd = ["terraform", command]

        if not prompt_approval:
            if command in ["apply", "destroy"]:
                full_cmd.append("-auto-approve")

        process = subprocess.Popen(full_cmd, cwd=TERRAFORM_DIR, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        # Stream output in real-time
        for line in iter(process.stdout.readline, ''):
            sys.stdout.write(line)
        process.wait()

        if process.returncode == 0:
            print(Fore.GREEN + f"\nTerraform {command} completed successfully." + Style.RESET_ALL)
            return True
        else:
            print(Fore.RED + f"\nTerraform {command} failed with exit code {process.returncode}." + Style.RESET_ALL)
            return False

    except Exception as e:
        print(Fore.RED + f"An unexpected error occurred during Terraform command execution: {e}" + Style.RESET_ALL)
        return False
    finally:
        # Restore original main.tf content only if it was modified for a non-persistent command
        if modules_to_enable is not None and command not in ["apply", "destroy"]:
             if os.path.exists(MAIN_TF_PATH) and original_content:
                with open(MAIN_TF_PATH, 'w') as f:
                    f.write(original_content)


def get_module_status():
    """Reads main.tf and returns the status (enabled/disabled/not found) of each module."""
    if not os.path.exists(MAIN_TF_PATH):
        return {}

    status = {}
    with open(MAIN_TF_PATH, 'r') as f:
        content = f.read()

    for key, module_info in MODULE_MAP.items():
        module_name = module_info["name"]
        pattern = r"(\/\*)?\s*module\s*\"" + re.escape(module_name) + r"\"\s*\{[\s\S]*?\}(\s*\*\/)?"
        match = re.search(pattern, content)

        if match:
            if match.group(1) and match.group(3):
                status[module_name] = False # Commented (disabled)
            else:
                status[module_name] = True  # Not commented (enabled)
        else:
            status[module_name] = "Not Found"

    return status

def manage_modules():
    """Allows the user to enable or disable specific Terraform modules via interactive menu."""
    while True:
        current_status = get_module_status()
        print(Fore.CYAN + "\n--- Manage Modules ---")
        print("Current Status:")
        for key, module_info in MODULE_MAP.items():
            name = module_info["name"]
            status_text = "Enabled" if current_status.get(name, False) else "Disabled"
            color = Fore.GREEN if current_status.get(name, False) else Fore.RED
            if current_status.get(name) == "Not Found":
                color = Fore.YELLOW
                status_text = "Not Found"
            print(f"{Fore.CYAN}{key}. {name}: {color}{status_text}{Style.RESET_ALL}")

        print("\nEnter module numbers to toggle (e.g., '2 3' to toggle Blue and Red Team), or 'done' to finish.")
        print(Fore.MAGENTA + "Note: Core network is usually required and its comment status should be managed carefully." + Style.RESET_ALL)
        
        sys.stdout.write(Fore.GREEN + "Your choice: " + Style.RESET_ALL)
        choice = input().strip().lower()

        if choice == "done":
            break
        
        selected_keys = choice.split()
        modules_to_toggle = []
        for skey in selected_keys:
            if skey in MODULE_MAP:
                modules_to_toggle.append(MODULE_MAP[skey]["name"])
            else:
                print(Fore.RED + f"Invalid module number: {skey}" + Style.RESET_ALL)
                
        if not modules_to_toggle:
            continue

        target_enabled_modules = []
        for map_key, module_info in MODULE_MAP.items():
            module_name = module_info["name"]
            if module_name in modules_to_toggle:
                if not current_status.get(module_name, False):
                    target_enabled_modules.append(module_name)
            elif current_status.get(module_name, True):
                target_enabled_modules.append(module_name)
        
        print(Fore.BLUE + "Applying module configuration changes in main.tf...")
        run_terraform_command("", modules_to_enable=target_enabled_modules, prompt_approval=False)
        print(Fore.GREEN + "Module configuration updated in main.tf." + Style.RESET_ALL)

def view_module_status():
    """Displays the current enabled/disabled status of all modules."""
    print(Fore.CYAN + "\n--- Current Module Status ---")
    status = get_module_status()
    if not status:
        print(Fore.YELLOW + "No modules found or main.tf is inaccessible." + Style.RESET_ALL)
        return

    for key, module_info in MODULE_MAP.items():
        name = module_info["name"]
        current_state = status.get(name)
        if current_state is True:
            print(f"{Fore.CYAN}{key}. {name}: {Fore.GREEN}Enabled{Style.RESET_ALL}")
        elif current_state is False:
            print(f"{Fore.CYAN}{key}. {name}: {Fore.RED}Disabled{Style.RESET_ALL}")
        else: # "Not Found"
            print(f"{Fore.CYAN}{key}. {name}: {Fore.YELLOW}Not Found (Check main.tf){Style.RESET_ALL}")
    print(Style.RESET_ALL)

def get_running_lab_instances(project_name="SOCLab"):
    """
    Identifies running EC2 instances belonging to the SOC Lab project.
    Uses 'Name' tag to identify the instance type (e.g., SecurityOnion, KaliLinux).
    """
    ec2 = boto3.client('ec2')
    running_instances = []
    
    try:
        # Filter instances by 'Project' tag and 'running' state
        response = ec2.describe_instances(
            Filters=[
                {'Name': 'tag:Project', 'Values': [project_name]},
                {'Name': 'instance-state-name', 'Values': ['running']}
            ]
        )

        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                instance_name = "N/A"
                for tag in instance.get('Tags', []):
                    if tag['Key'] == 'Name':
                        instance_name = tag['Value']
                        break
                
                # Derive a simplified type for AMI mapping (e.g., "SOCLab-SecurityOnion" -> "securityonion")
                simplified_name = instance_name.replace(f"{project_name}-", "").lower().replace("-", "")

                ami_key_found = None
                # Iterate through MODULE_MAP to find the corresponding ami_type_map
                for module_key, module_info in MODULE_MAP.items():
                    if "ami_type_map" in module_info:
                        for vm_name_part, ami_key_candidate in module_info["ami_type_map"].items():
                            if vm_name_part in simplified_name: # Check if the instance name contains the VM type part
                                ami_key_found = ami_key_candidate
                                break # Found a match, no need to check other vm_name_parts in this module
                    if ami_key_found:
                        break # Found a match in a module, no need to check other modules

                running_instances.append({
                    "InstanceId": instance_id,
                    "Name": instance_name,
                    "AmiKey": ami_key_found # Store the determined AMI key (e.g., "security_onion_ami_id")
                })
    except Exception as e:
        print(Fore.RED + f"Error getting running instances: {e}" + Style.RESET_ALL)
    return running_instances

def capture_amis_from_running_instances(project_name="SOCLab"):
    """
    Guides the user to select running lab instances and creates custom AMIs from them.
    Updates custom_amis.json with the new AMI IDs.
    """
    print(Fore.CYAN + "\n--- Capture Custom AMIs ---")
    ec2 = boto3.client('ec2')
    
    running_instances = get_running_lab_instances(project_name)
    if not running_instances:
        print(Fore.YELLOW + "No running SOC Lab instances found to capture AMIs from. Deploy the lab first and configure it." + Style.RESET_ALL)
        return

    print("Found the following running SOC Lab instances:")
    for i, inst in enumerate(running_instances):
        # Display the instance name and derived AMI key for clarity
        ami_key_display = inst['AmiKey'] if inst['AmiKey'] else Fore.RED + "UNMAPPED (AMI not savable via script)" + Style.RESET_ALL
        print(f"{Fore.CYAN}{i+1}. {inst['Name']} (ID: {inst['InstanceId']}, AMI Key: {ami_key_display}){Style.RESET_ALL}")

    sys.stdout.write(Fore.GREEN + "Enter numbers of instances to snapshot (e.g., '1 3'), 'all', or 'cancel': " + Style.RESET_ALL)
    choice = input().strip().lower()

    if choice == "cancel":
        print(Fore.YELLOW + "AMI capture cancelled." + Style.RESET_ALL)
        return
    
    selected_instances = []
    if choice == "all":
        selected_instances = [inst for inst in running_instances if inst['AmiKey']] # Only select if a key is mapped
        if not selected_instances:
            print(Fore.YELLOW + "No mappable instances found to capture AMIs from. Please ensure instances are tagged with 'Name' appropriately." + Style.RESET_ALL)
            return
    else:
        try:
            indices = [int(x) - 1 for x in choice.split()]
            for idx in indices:
                if 0 <= idx < len(running_instances):
                    if running_instances[idx]['AmiKey']:
                        selected_instances.append(running_instances[idx])
                    else:
                        print(Fore.YELLOW + f"Instance {idx+1} ({running_instances[idx]['Name']}) has no AMI key mapping. Skipping." + Style.RESET_ALL)
                else:
                    print(Fore.RED + f"Invalid instance number: {idx+1}. Skipping." + Style.RESET_ALL)
        except ValueError:
            print(Fore.RED + "Invalid input. Please enter numbers separated by spaces, 'all', or 'cancel'." + Style.RESET_ALL)
            return

    if not selected_instances:
        print(Fore.YELLOW + "No valid instances selected for AMI capture." + Style.RESET_ALL)
        return

    captured_ami_map = {}
    for inst in selected_instances:
        instance_id = inst['InstanceId']
        instance_name = inst['Name']
        ami_key = inst['AmiKey'] # This should now be guaranteed to exist for selected_instances

        ami_name = f"{instance_name}-Configured-{time.strftime('%Y%m%d-%H%M%S')}"
        ami_description = f"Custom AMI for {instance_name} in {project_name} lab, configured state."

        print(Fore.BLUE + f"Creating AMI for {instance_name} (ID: {instance_id}). AMI Name: {ami_name}..." + Style.RESET_ALL)
        try:
            image_response = ec2.create_image(
                InstanceId=instance_id,
                Name=ami_name,
                Description=ami_description,
                NoReboot=True # Important: Creates AMI without rebooting the instance
            )
            ami_id = image_response['ImageId']
            print(Fore.BLUE + f"AMI creation initiated for {instance_name}. AMI ID: {ami_id}. Waiting for completion..." + Style.RESET_ALL)

            # Wait for AMI to be available
            waiter = ec2.get_waiter('image_available')
            waiter.wait(ImageIds=[ami_id], WaiterConfig={'Delay': 15, 'MaxAttempts': 120}) # Check every 15s for up to 30 mins
            
            print(Fore.GREEN + f"AMI {ami_id} for {instance_name} is available." + Style.RESET_ALL)
            captured_ami_map[ami_key] = ami_id

        except Exception as e:
            print(Fore.RED + f"Error creating AMI for {instance_name}: {e}" + Style.RESET_ALL)
    
    if captured_ami_map:
        update_custom_amis_file(captured_ami_map)
        print(Fore.GREEN + "Custom AMI capture process completed." + Style.RESET_ALL)
    else:
        print(Fore.YELLOW + "No AMIs were successfully captured." + Style.RESET_ALL)


def update_custom_amis_file(new_ami_map):
    """
    Reads existing custom_amis.json, merges new AMI IDs, and writes back.
    :param new_ami_map: Dictionary of {ami_key: ami_id} to add/update.
    """
    current_amis = {}
    if os.path.exists(CUSTOM_AMIS_JSON_PATH):
        try:
            with open(CUSTOM_AMIS_JSON_PATH, 'r') as f:
                current_amis = json.load(f)
        except json.JSONDecodeError:
            print(Fore.YELLOW + f"Warning: {CUSTOM_AMIS_JSON_PATH} is malformed. Starting with empty AMIs." + Style.RESET_ALL)
            current_amis = {}
    
    current_amis.update(new_ami_map)

    try:
        with open(CUSTOM_AMIS_JSON_PATH, 'w') as f:
            json.dump(current_amis, f, indent=2)
        print(Fore.GREEN + f"Updated custom AMI mappings in {CUSTOM_AMIS_JSON_PATH}" + Style.RESET_ALL)
    except Exception as e:
        print(Fore.RED + f"Error writing to {CUSTOM_AMIS_JSON_PATH}: {e}" + Style.RESET_ALL)

def view_custom_amis_mapping():
    """Displays the current content of custom_amis.json."""
    print(Fore.CYAN + "\n--- Current Custom AMI Mappings ---")
    if not os.path.exists(CUSTOM_AMIS_JSON_PATH):
        print(Fore.YELLOW + f"'{CUSTOM_AMIS_JSON_PATH}' not found. No custom AMIs defined yet." + Style.RESET_ALL)
        return

    try:
        with open(CUSTOM_AMIS_JSON_PATH, 'r') as f:
            amis = json.load(f)
            if not amis:
                print(Fore.YELLOW + "No custom AMIs are currently mapped in the file." + Style.RESET_ALL)
            else:
                for key, ami_id in amis.items():
                    print(f"{Fore.CYAN}{key}: {Fore.MAGENTA}{ami_id}{Style.RESET_ALL}")
    except json.JSONDecodeError:
        print(Fore.RED + f"Error: '{CUSTOM_AMIS_JSON_PATH}' is not a valid JSON file." + Style.RESET_ALL)
    except Exception as e:
        print(Fore.RED + f"An error occurred reading '{CUSTOM_AMIS_JSON_PATH}': {e}" + Style.RESET_ALL)
    print(Style.RESET_ALL)


def main():
    while True:
        print_menu()
        sys.stdout.write(Fore.GREEN + "Enter your choice: " + Style.RESET_ALL)
        choice = input().strip()

        if choice == '1':
            run_terraform_command("init", prompt_approval=False)
        elif choice == '2':
            run_terraform_command("plan", modules_to_enable=None, prompt_approval=False)
        elif choice == '3':
            active_modules = [name for name, enabled in get_module_status().items() if enabled]
            run_terraform_command("apply", modules_to_enable=active_modules, prompt_approval=True)
        elif choice == '4':
            active_modules = [name for name, enabled in get_module_status().items() if enabled]
            run_terraform_command("destroy", modules_to_enable=active_modules, prompt_approval=True)
        elif choice == '5':
            manage_modules()
        elif choice == '6':
            view_module_status()
        elif choice == '7':
            # Assumes project name "SOCLab" is used in tags.
            # You could make this configurable or retrieve from terraform.tfvars programmatically.
            capture_amis_from_running_instances(project_name="SOCLab")
        elif choice == '8':
            view_custom_amis_mapping()
        elif choice == '9':
            print(Fore.GREEN + "Exiting. Goodbye!" + Style.RESET_ALL)
            sys.exit(0)
        else:
            print(Fore.RED + "Invalid choice. Please try again." + Style.RESET_ALL)

if __name__ == "__main__":
    main()
