# Using Roles to simplify the installation and management
- Structure
            project/
            ├── ansible/
            │   ├── playbook.yml
            │   ├── roles/
            │   │   ├── common/
            │   │   │   ├── tasks/
            │   │   │   │   └── main.yml
            │   │   ├── docker_build/
            │   │   │   ├── tasks/
            │   │   │   │   └── main.yml
            │   ├── vars/
            │   │   └── main.yml
- In this playbook.yaml
    - The common role is applied to all nodes to install AWS CLI and Docker.
    - The docker_build role is applied to the Ansible controller to build and push the Docker image.
    - The docker_compose role is applied to the name_dev_app_* group, which corresponds to the EC2 instances tagged with names like dev-app-1, dev-app-2, etc.

# Detailed Explanation

## Purpose
This Ansible project is designed to automate the setup and management of AWS EC2 instances, Docker, and Docker Compose. It uses Ansible roles to modularize the tasks and make the playbook easier to manage and extend.

## Roles

### Common Role
- **Path**: `roles/common/tasks/main.yml`
- **Purpose**: Install AWS CLI and Docker on all nodes.
- **Tasks**:
  - Update the package manager.
  - Install AWS CLI.
  - Install Docker.
  - Start and enable Docker service.

### Docker Build Role
- **Path**: `roles/docker_build/tasks/main.yml`
- **Purpose**: Build and push Docker images from the Ansible controller.
- **Tasks**:
  - Log in to the ECR registry.
  - Build the Docker image.
  - Tag the Docker image.
  - Push the Docker image to the ECR registry.

### Docker Compose Role
- **Path**: `roles/docker_compose/tasks/main.yml`
- **Purpose**: Deploy Docker Compose applications on EC2 instances.
- **Tasks**:
  - Install Docker Compose.
  - Deploy the Docker Compose application.

## How to Use

1. **Inventory File**: Update the `inventory_aws_ec2.yml` file with your EC2 instances.
2. **Variables**: Update the `vars/main.yml` file with your specific variables such as AWS region and ECR registry.
3. **Run the Playbook**: Execute the playbook using the following command:
    ```sh
    ansible-playbook -i inventory_aws_ec2.yml playbook.yml --extra-vars "aws_region=us-east-1 ecr_registry=123456789012.dkr.ecr.us-east-1.amazonaws.com"
    ```

This will set up the necessary environment on your EC2 instances, build and push the Docker image, and deploy the Docker Compose application.

