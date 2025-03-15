# #Running ansible
- Run following playbook to login the ecr on Jenkins and app node
```sh
ansible-playbook -i inventory_aws_ec2.yml playbook.yml --extra-vars "aws_region=us-east-1 ecr_registry=123456789012.dkr.ecr.us-east-1.amazonaws.com"
```