import subprocess
import os
import re
import time
from colorama import Fore, Style, init 

# Initialize colorama for cross-platform colored output
init(autoreset=True)

# --- Configuration ---
TERRAFORM_DIR = "./terraform" # Path to your terraform directory
MAIN_TF_PATH = os.path.join(TERRAFORM_DIR, "main.tf")
COMMON_TFVARS_PATH = os.path.join(TERRAFORM_DIR, "terraform.tfvars") # Assuming you have a terraform.tfvars for vars

# Toggle for verbose debug output (True/False)
DEBUG_MODE = False # Set to False for clean output, True for detailed debugging
# Toggle for colored output (True/False)
COLORED_OUTPUT = True

# --- Module Definitions for Script Control ---
# Define the unique identifier for each module block in main.tf
# These are used to find the module's content and its comment markers.
MODULE_DEFINITIONS = {
    "blue_team": {
        "start_line_marker": "module \"blue_team\" {",
        "name_pretty": "Blue Team Operations"
    },
    "red_team": {
        "start_line_marker": "module \"red_team\" {",
        "name_pretty": "Red Team Operations"
    },
    "forensics_team": {
        "start_line_marker": "module \"forensics_team\" {",
        "name_pretty": "Forensics Operations"
    },
    "it_infrastructure": {
        "start_line_marker": "module \"it_infrastructure\" {",
        "name_pretty": "IT Infrastructure Department"
    }
}

# --- Helper Functions ---

# CORRECTED print_colored function to accept and pass 'end' argument
def print_colored(text, color=Fore.WHITE, style=Style.NORMAL, **kwargs):
    """Prints text with optional color and style, accepting additional print arguments like 'end'."""
    if COLORED_OUTPUT:
        print(f"{color}{style}{text}{Style.RESET_ALL}", **kwargs)
    else:
        print(text, **kwargs)

def run_terraform_command(command_parts, module_pretty_name="Terraform", include_vars=True):
    """Executes a Terraform command."""
    try:
        full_command = ["terraform"] + command_parts

        if include_vars: # Only add vars if include_vars is True
            # Add common variables from terraform.tfvars if it exists
            tf_vars = []
            if os.path.exists(COMMON_TFVARS_PATH):
                with open(COMMON_TFVARS_PATH, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#'):
                            try:
                                key, val = line.split('=', 1)
                                tf_vars.append(f"-var={key.strip()}={val.strip().strip('\"')}")
                            except ValueError:
                                pass # Ignore lines that don't match key=value format

            # Add other essential variables directly (adjust as per your setup)
            # IMPORTANT: Ensure 'soc-lab-key' here matches your actual key pair name in AWS.
            # You might want to get these from environment variables or a config file for production
            aws_region = "ap-south-1" # Example: "us-east-1"
            key_pair_name = "soc-lab-key" # <--- CONFIRM THIS EXACTLY MATCHES AWS KEY PAIR NAME
            your_public_ip = "0.0.0.0/0" # Example: "YOUR_PUBLIC_IP/32" or "0.0.0.0/0" for anywhere (less secure)

            if aws_region: tf_vars.append(f"-var=aws_region={aws_region}")
            if key_pair_name: tf_vars.append(f"-var=key_pair_name={key_pair_name}")
            if your_public_ip: tf_vars.append(f"-var=your_public_ip={your_public_ip}")

            full_command.extend(tf_vars) # Add vars only if include_vars is True

        print_colored(f"\nRunning Terraform command: {' '.join(full_command)}", Fore.CYAN)
        process = subprocess.run(full_command, cwd=TERRAFORM_DIR, capture_output=True, text=True, check=True)
        print(process.stdout) # Terraform's own output is usually good
        if process.stderr:
            print_colored(f"STDERR:\n{process.stderr}", Fore.YELLOW)
        return True
    except subprocess.CalledProcessError as e:
        print_colored(f"\nError executing Terraform command for {module_pretty_name}: {' '.join(e.cmd)}", Fore.RED, Style.BRIGHT)
        print_colored(f"Exit code: {e.returncode}", Fore.RED)
        print_colored(f"STDOUT:\n{e.stdout}", Fore.RED)
        print_colored(f"STDERR:\n{e.stderr}", Fore.RED)
        return False
    except FileNotFoundError:
        print_colored("Error: 'terraform' command not found. Please ensure Terraform is installed and in your PATH.", Fore.RED, Style.BRIGHT)
        return False

def get_terraform_outputs():
    """Fetches and prints Terraform outputs."""
    print_colored("\n--- Fetching Terraform Outputs ---", Fore.MAGENTA, Style.BRIGHT)
    # Pass include_vars=False for the output command
    return run_terraform_command(["output", "-json"], include_vars=False)


def modify_module_comment_status(module_name, uncomment=True):
    """
    Modifies the comment status of a specific module in main.tf.
    If uncomment is True, it removes /* */. If False, it adds /* */.
    Returns (success_status, was_modified).
    success_status: True if the operation was processed (modified or already in desired state), False if an error occurred (e.g. module not found).
    was_modified: True if the file content was actually changed, False otherwise.
    """
    if module_name not in MODULE_DEFINITIONS:
        print_colored(f"Error: Module '{module_name}' not defined for modification.", Fore.RED)
        return (False, False)

    module_info = MODULE_DEFINITIONS[module_name]
    
    with open(MAIN_TF_PATH, 'r') as f:
        content = f.read()

    # Regex to find the module block, whether it's commented or not
    # Optimized to reduce unnecessary trailing whitespace capture in module_content_inner.
    pattern_str = r'(\s*/\*\s*)?' # Group 1: Optional leading /* with any surrounding whitespace
    pattern_str += r'(\s*)'      # Group 2: Capture leading whitespace for indentation
    # Group 3: The actual module block, ending just at its closing brace '}'
    # Removed the final `\s*` from this group to prevent it from consuming excess newlines after the '}'.
    pattern_str += r'(module\s*\"' + re.escape(module_name) + r'\"\s*\{.*?^\s*\})' 
    # Group 4: Optional trailing */ with any surrounding whitespace/newlines that might follow Group 3.
    pattern_str += r'(\s*\*/\s*)?' 

    # Use re.DOTALL to make '.' match newlines, and re.MULTILINE for '^' to match line start
    module_block_regex = re.compile(pattern_str, re.DOTALL | re.MULTILINE)

    match = module_block_regex.search(content)

    if not match:
        print_colored(f"Warning: Could not find module '{module_name}' in {MAIN_TF_PATH}. Skipping modification.", Fore.YELLOW)
        return (False, False) # Indicate failure to find module
    
    current_full_block = match.group(0) # The entire matched string (with or without comments)
    leading_comment = match.group(1)
    leading_indent = match.group(2)
    module_content_inner = match.group(3) # Just the module { ... } block
    trailing_comment = match.group(4)
    
    new_full_block = ""
    was_modified = False # Tracks if the file content was actually changed

    # Apply rstrip to remove excessive trailing newlines/whitespace from the captured module content
    # This helps in making the output more compact.
    cleaned_module_content_inner = module_content_inner.rstrip()

    if uncomment:
        # If we want to uncomment, remove /* */.
        # Ensure a newline precedes and follows the uncommented block to prevent concatenation
        # with previous/next lines if the original /* and */ were on separate lines.
        if leading_comment and trailing_comment: # Check if comments were actually found and will be removed
             new_full_block = "\n" + leading_indent + cleaned_module_content_inner + "\n"
             was_modified = True
             print_colored(f"Uncommenting {module_name} in main.tf...", Fore.GREEN)
        else:
            print_colored(f"{module_name} is already uncommented. No change needed.", Fore.BLUE)
            new_full_block = current_full_block # No modification to content
    else: # Re-comment the block
        # Add /* and */ around the module body
        if not leading_comment and not trailing_comment: # Only comment if not already commented
            new_full_block = f"{leading_indent}/*\n{leading_indent}{cleaned_module_content_inner}\n{leading_indent}*/"
            was_modified = True
            print_colored(f"Commenting {module_name} in main.tf...", Fore.GREEN)
        else:
            print_colored(f"{module_name} is already commented. No change needed.", Fore.BLUE)
            new_full_block = current_full_block # No modification to content

    if DEBUG_MODE: # Condense debug output for readability
        print_colored(f"\n--- DEBUG: State for {module_name} (uncomment={uncomment}) ---", Fore.LIGHTBLACK_EX)
        print_colored(f"  Captured Full Block (Group 0):\n{current_full_block.strip()}", Fore.LIGHTBLACK_EX)
        print_colored(f"  Captured Module Content (Group 3 - raw):\n{module_content_inner.strip()}", Fore.LIGHTBLACK_EX)
        print_colored(f"  Cleaned Module Content (rstrip applied to G3):\n{cleaned_module_content_inner.strip()}", Fore.LIGHTBLACK_EX)
        if was_modified:
            print_colored(f"  New Block (to be written):\n{new_full_block.strip()}", Fore.LIGHTBLACK_EX)
        print_colored("--- END DEBUG ---", Fore.LIGHTBLACK_EX)

    if was_modified:
        # Perform replacement only if modification happened
        new_content = content.replace(current_full_block, new_full_block, 1)

        with open(MAIN_TF_PATH, 'w') as f:
            f.write(new_content)
        return (True, True) # Successfully modified
    
    return (True, False) # Successfully processed, but no modification was needed


def deploy_selected_module(module_name):
    """Handles the deployment of a selected team module."""
    module_pretty_name = MODULE_DEFINITIONS[module_name]["name_pretty"]
    print_colored(f"Attempting to deploy {module_pretty_name}...", Fore.CYAN, Style.BRIGHT)

    # Step 1: Ensure the module is uncommented in main.tf
    # We proceed even if it was already uncommented (status=True, was_modified=False)
    status, _ = modify_module_comment_status(module_name, uncomment=True)
    if not status: # Only fail if modify_module_comment_status had an actual error (e.g., module not found)
        print_colored(f"Deployment failed for {module_pretty_name}: Could not process module comment status.", Fore.RED)
        return

    # Step 2: Run terraform init (reconfigure to pick up module changes)
    if not run_terraform_command(["init", "-reconfigure"]):
        print_colored(f"Deployment failed for {module_pretty_name}: Terraform init failed.", Fore.RED)
        return

    # Step 3: Run terraform apply, targeting only the selected module
    if not run_terraform_command(["apply", "-auto-approve", f"-target=module.{module_name}"]):
        print_colored(f"Deployment failed for {module_pretty_name}: Terraform apply failed.", Fore.RED)
        return

    print_colored(f"Successfully deployed {module_pretty_name}.", Fore.GREEN, Style.BRIGHT)

def destroy_selected_module(module_name):
    """Handles the destruction of a selected team module."""
    module_pretty_name = MODULE_DEFINITIONS[module_name]["name_pretty"]
    print_colored(f"Attempting to destroy {module_pretty_name}...", Fore.CYAN, Style.BRIGHT)

    # Step 1: Ensure the module is uncommented in main.tf (needed for destroy -target)
    # We proceed even if it was already uncommented (status=True, was_modified=False)
    status, _ = modify_module_comment_status(module_name, uncomment=True)
    if not status: # Only fail if modify_module_comment_status had an actual error
        print_colored(f"Destruction failed for {module_pretty_name}: Could not process module comment status.", Fore.RED)
        return

    # Step 2: Run terraform init (reconfigure to pick up module changes)
    if not run_terraform_command(["init", "-reconfigure"]):
        print_colored(f"Destruction failed for {module_pretty_name}: Terraform init failed.", Fore.RED)
        return

    # Step 3: Run terraform destroy, targeting only the selected module
    if not run_terraform_command(["destroy", "-auto-approve", f"-target=module.{module_name}"]):
        print_colored(f"Destruction failed for {module_pretty_name}: Terraform destroy failed.", Fore.RED)
        return

    # Step 4: Re-comment the module in main.tf after destruction
    # This step should only warn if there's a problem commenting it back, not halt destruction.
    comment_status, _ = modify_module_comment_status(module_name, uncomment=False)
    if not comment_status:
        print_colored(f"Warning: Failed to re-comment {module_pretty_name} in main.tf after destruction. Please check main.tf manually.", Fore.YELLOW)
    
    print_colored(f"Successfully destroyed {module_pretty_name}.", Fore.GREEN, Style.BRIGHT)

def destroy_all_resources():
    """Destroys all resources managed by the Terraform configuration."""
    print_colored("\n--- WARNING: DESTROYING ALL LAB RESOURCES ---", Fore.RED, Style.BRIGHT)
    print_colored("This will destroy ALL resources managed by this Terraform configuration,", Fore.RED)
    print_colored("including the Core Network, Blue Team, Red Team, Forensics, and IT Infrastructure.", Fore.RED)
    print_colored("This action is irreversible and will incur costs if not completed.", Fore.RED)
    
    print_colored("Type 'destroy all' to confirm this action: ", Fore.YELLOW, Style.BRIGHT, end="")
    confirmation = input().strip() # Added end="" here too

    if confirmation.lower() != "destroy all":
        print_colored("Destruction cancelled.", Fore.YELLOW)
        return

    print_colored("\nProceeding with destruction of all resources...", Fore.CYAN, Style.BRIGHT)

    # Step 1: Ensure all optional team modules are uncommented so Terraform can see them for destruction
    print_colored("Ensuring all team modules are uncommented in main.tf for destruction...", Fore.CYAN)
    all_modules_prepared_successfully = True
    for module_name in MODULE_DEFINITIONS.keys():
        status, _ = modify_module_comment_status(module_name, uncomment=True)
        if not status:
            all_modules_prepared_successfully = False
            print_colored(f"Warning: Failed to ensure {module_name} is uncommented. It might not be destroyed.", Fore.YELLOW)
    
    if not all_modules_prepared_successfully:
        print_colored("Warning: Not all modules could be prepared for destruction. Proceeding, but review manually.", Fore.YELLOW, Style.BRIGHT)
        time.sleep(2) # Give user time to read warning

    # Step 2: Run terraform init (reconfigure to pick up any module changes)
    if not run_terraform_command(["init", "-reconfigure"]):
        print_colored("Failed to initialize Terraform for all-resource destruction.", Fore.RED)
        return

    # Step 3: Run terraform destroy without targets to destroy everything
    if not run_terraform_command(["destroy", "-auto-approve"]):
        print_colored("Failed to destroy all resources.", Fore.RED)
        return

    print_colored("\nSuccessfully initiated destruction of all resources.", Fore.GREEN, Style.BRIGHT)
    print_colored("--- Post-destruction Cleanup ---", Fore.MAGENTA, Style.BRIGHT)
    # Step 4: Re-comment all optional team modules in main.tf after destruction
    # This ensures main.tf is clean.
    print_colored("Re-commenting all optional team modules in main.tf...", Fore.CYAN)
    for module_name in MODULE_DEFINITIONS.keys():
        modify_module_comment_status(module_name, uncomment=False)
    
    print_colored("Cleanup complete. All resources should be destroyed or in process of destruction.", Fore.GREEN, Style.BRIGHT)


# --- Main Script Logic ---
def main():
    # Initial setup: Ensure all team modules are commented out when the script starts
    print_colored("Initializing deployment script...", Fore.BLUE)
    for module_name in MODULE_DEFINITIONS.keys():
        # We don't care if it was already commented, just ensure it's processed.
        modify_module_comment_status(module_name, uncomment=False)
    print_colored("Main.tf reset to default commented state for team modules.", Fore.BLUE)
    
    while True:
        print_colored("\n--- SOC Lab Deployment Menu ---", Fore.GREEN, Style.BRIGHT)
        print_colored("1. Deploy Core Network (VPC, Subnets, NAT Instance, common SGs)", Fore.WHITE)
        print_colored("2. Deploy Blue Team Operations", Fore.WHITE)
        print_colored("3. Deploy Red Team Operations", Fore.WHITE)
        print_colored("4. Deploy Forensics Operations", Fore.WHITE)
        print_colored("5. Deploy IT Infrastructure Department", Fore.WHITE)
        print_colored("6. Destroy Blue Team Operations", Fore.YELLOW)
        print_colored("7. Destroy Red Team Operations", Fore.YELLOW)
        print_colored("8. Destroy Forensics Operations", Fore.YELLOW)
        print_colored("9. Destroy IT Infrastructure Department", Fore.YELLOW)
        print_colored("10. Destroy Core Network (Careful! Destroys almost everything!)", Fore.RED)
        print_colored("11. Destroy ALL Resources (CAUTION!)", Fore.RED, Style.BRIGHT)
        print_colored("12. Show all Terraform Outputs", Fore.MAGENTA)
        print_colored("13. Exit", Fore.CYAN) 

        # CORRECTED LINE: First print the prompt using print_colored with end="", then get input.
        print_colored("Enter your choice: ", Fore.GREEN, end="") 
        choice = input().strip()

        if choice == '1':
            print_colored("Attempting to deploy Core Network (VPC, Subnets, NAT Instance, common SGs)...", Fore.CYAN, Style.BRIGHT)
            if run_terraform_command(["init", "-reconfigure"]) and \
               run_terraform_command(["apply", "-auto-approve", "-target=module.core_network"]):
                print_colored("Successfully deployed Core Network.", Fore.GREEN, Style.BRIGHT)
                get_terraform_outputs()
            else:
                print_colored("Failed to deploy Core Network.", Fore.RED, Style.BRIGHT)
        elif choice == '2':
            deploy_selected_module("blue_team")
        elif choice == '3':
            deploy_selected_module("red_team")
        elif choice == '4':
            deploy_selected_module("forensics_team")
        elif choice == '5':
            deploy_selected_module("it_infrastructure")
        elif choice == '6':
            destroy_selected_module("blue_team")
        elif choice == '7':
            destroy_selected_module("red_team")
        elif choice == '8':
            destroy_selected_module("forensics_team")
        elif choice == '9':
            destroy_selected_module("it_infrastructure")
        elif choice == '10':
            print_colored("Attempting to destroy Core Network...", Fore.RED, Style.BRIGHT)
            print_colored("Commenting out all optional team modules before core network destruction...", Fore.YELLOW)
            for module_name in MODULE_DEFINITIONS.keys():
                modify_module_comment_status(module_name, uncomment=False)
            time.sleep(1) # Give a moment for file write
            
            if run_terraform_command(["init", "-reconfigure"]) and \
               run_terraform_command(["destroy", "-auto-approve", "-target=module.core_network"]):
                print_colored("Successfully destroyed Core Network.", Fore.GREEN, Style.BRIGHT)
            else:
                print_colored("Failed to destroy Core Network.", Fore.RED, Style.BRIGHT)
        elif choice == '11': 
            destroy_all_resources()
        elif choice == '12':
            get_terraform_outputs()
        elif choice == '13':
            print_colored("Exiting.", Fore.CYAN, Style.BRIGHT)
            # Ensure main.tf is clean before exiting: re-comment all optional modules
            for module_name in MODULE_DEFINITIONS.keys():
                modify_module_comment_status(module_name, uncomment=False)
            break
        else:
            print_colored("Invalid choice. Please try again.", Fore.RED)

if __name__ == "__main__":
    main()