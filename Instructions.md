# Instructions to Run the Project
1. Set up the lab server in AWS with admin access to perform Terraform actions with ssh (port 22) from your local public IP.
2. Clone the repository [ht-practice-work](https://github.com/htpractice/ht-practice-work.git) and switch to following branch
    - *git checkout **devopsninja-project***
3. Change the directory to **project** where you will find Jenkins, Ansible, Docker, movie-app, and Terraform.
4. Change to terraform/s3-db -> here you will set up the remote backend and DynamoDB lock to use later in the project.
    - Create S3 backend with dynamodb lock using followig commands
        - terraform init
        - terraform plan
        - terraform apply
5. Change to terraform/infra -> add the IP of your local machine as variable my_local_IP in dev.tfvars.
6. Create the infra using the following three commands:
    - terraform init
    - terraform plan -var-file=dev.tfvars
    - terraform apply -var-file=dev.tfvars
7. Go to the bastion host (Ansible controller) from the lab server or local machine (either is fine as it's in the public subnet), using private-key.pem stored in terraform/infra of your git repo.
8. Clone the repository [ht-practice-work](https://github.com/htpractice/ht-practice-work.git) and switch to following branch
    - *git checkout **devopsninja-project***
9. Run the following command to check the connectivity to all the hosts with tags app, jenkins and linux-bastion
    - *ansible -m ping all -i inventory_aws_ec2.yml*
10. Run the following command to configure the app and Jenkins host to get Docker friendly with AWS CLI:
    - Edit the vars/main.yml file to add the aws account number and try to keep the repo names as is.
    - *ansible-playbook -i inventory_aws_ec2.yml playbook.yml*
11. Go to the Jenkins node, pull the Jenkins image using the following command, and run it:
    - sudo docker pull <your_ecr_registry>/dev-jenkins-repo:latest
    - sudo docker tag <your_ecr_registry>/dev-jenkins-repo:latest jenkins
    - sudo docker run -itd --name jenkins-docker --user root -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock -e JENKINS_OPTS="--prefix=/jenkins" jenkins
        - Using a mount ensures all your jenkins data is stored on ec2, next time you spin up container it can access the data(used bind mounting here to keep data intact)
12. Login to windows bastion using private_key.pem which will generate password to login.
    - Use Windows APP (RDP is enabled on SG attached to bastion from my_local_IP variable)
13. Connect to jenkins and configure the project to have pipeline job which will use github to run Jenkinsfile.
    - First job may fail. Don't worry start a second job with Build with parameter option