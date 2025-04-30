# # Terraform modules for creating infrastructure

## Overview
This project uses Terraform to create and manage AWS infrastructure, including VPC, security groups, EC2 instances, and ALBs. Ansible is used to configure the instances.

## Terraform Files

### `main.tf`
This file calls all the modules to create the infrastructure.

### `variables.tf`
This file defines all the variables used in the Terraform configuration.

### `network.tf`
This file creates the VPC, subnets, and route tables.

- **VPC Module**: Creates the VPC and subnets.
- **Route Tables**: Creates route tables for public and private subnets.
- **Security Groups**: Creates security groups for bastion host, private instances, and public instances.

### `ec2_hosts.tf`
This file creates the EC2 instances and configures them.

- **TLS Private Key**: Generates a new RSA private key.
- **AWS Key Pair**: Creates a new key pair in AWS using the public key from the TLS private key.
- **Local File**: Stores the private key in a file.
- **Bastion Host**: Creates the bastion host.
- **Provision Bastion**: Uses a null_resource to run provisioners on the bastion host.
- **Jenkins Server**: Creates the Jenkins server.
- **App Instances**: Creates the app instances.
- **Windows Bastion Host**: Creates a Windows bastion host with a 30GB root volume.

### `alb.tf`
This file creates the Application Load Balancers (ALBs).

- **App ALB**: Creates an ALB for the app instances.
- **Jenkins ALB**: Creates an internal ALB for the Jenkins node.

### `outputs.tf`
This file defines the outputs for the Terraform configuration.

### `inventory_aws_ec2.yml`
This file is an Ansible inventory file that specifies the region and filters for the EC2 instances.

### `playbook.yml`
This file is an Ansible playbook that installs Docker on the EC2 instances and runs the Jenkins container.

## Running the Project

### Generate AWS Key
Generate an AWS key using the Terraform resource block.

- **TLS Private Key**: The `tls_private_key` resource generates a new RSA private key.
- **AWS Key Pair**: The `aws_key_pair` resource creates a new key pair in AWS using the public key from the `tls_private_key` resource.
- **Key Name in EC2 Instances**: The `key_name` parameter in the EC2 instance modules is updated to use the newly created key pair.
- **Output Block**: The `output` block outputs the private key in PEM format. The `sensitive` attribute is set to `true` to ensure that the private key is not displayed in the Terraform plan or apply output.

# #Run the following command post instance and key creation to get the private key file:

```sh
terraform output -raw private_key_pem > private_key.pem
chmod 600 private_key.pem
```