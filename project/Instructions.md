# Instructions to Run the Project
1. Set up the lab server in AWS with admin access to perform Terraform actions.
2. Clone the repository [ht-practice-work](https://github.com/htpractice/ht-practice-work.git).
3. Change the directory to **project** where you will find Jenkins, Ansible, Docker, movie-app, and Terraform.
4. Change to terraform/s3-db -> here you will set up the remote backend and DynamoDB lock to use later in the project.
5. Change to terraform/infra -> add the IP of your local machine as variable my_local_IP in dev.tfvars.
6. Create the infra using the following three commands:
    - terraform init
    - terraform plan -var-file=dev.tfvars
    - terraform apply -var-file=dev.tfvars
7. Go to the bastion host (Ansible controller) from the lab server or local machine (either is fine as it's in the public subnet), using private-key.pem stored in terraform/infra of your git repo.
8. Clone the repository [ht-practice-work](https://github.com/htpractice/ht-practice-work.git).
9. Run the following command to configure the app and Jenkins host to get Docker friendly with AWS CLI:
    - ansible-playbook -i inventory_aws_ec2.yml playbook.yml
10. Go to the Jenkins node, pull the Jenkins image using the following command, and run it:
    - docker pull <your_ecr_registry>/dev-jenkins-repo:latest
    - docker tag <your_ecr_registry>/dev-jenkins-repo:latest jenkins
    - sudo docker run -itd --user root --name myjenkins -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:/var/jenkins_home -e JENKINS_OPTS="--prefix=/jenkins" jenkins
11. Login to windows bastion using private_key.pem which will generate password to login usin