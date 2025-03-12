# Generate a new SSH key pair and use it to launch EC2 instances
resource "tls_private_key" "instance_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a key pair for the instances to use for SSH access
resource "aws_key_pair" "generated_key" {
  key_name   = "${var.environment}-key"
  public_key = tls_private_key.instance_key.public_key_openssh
}
# Store th ekey in a file
resource "local_file" "private_key_pem" {
  content              = tls_private_key.instance_key.private_key_pem
  filename             = "private_key.pem"
  file_permission      = "0600"
}

# Create the bastion host
module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name           = "${var.environment}-bastion"
  ami            = var.ami
  instance_type  = var.instance_type
  associate_public_ip_address = true
  key_name       = aws_key_pair.generated_key.key_name
  subnet_id      = module.devops-ninja-vpc.public_subnets[0]
  vpc_security_group_ids = [module.bastion_sg.security_group_id]
  iam_instance_profile = aws_iam_instance_profile.bastion_instance_profile.name

  tags = {
    Name = "${var.environment}-bastion"
    Environment = var.environment
  }
}

# Use null_resource to run provisioner on bastion host
resource "null_resource" "provision_bastion" {
  depends_on = [module.bastion]

  provisioner "file" {
    source      = local_file.private_key_pem.filename
    destination = "/home/ubuntu/private_key.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"  # Adjust this based on your AMI
      private_key = tls_private_key.instance_key.private_key_pem
      host        = module.bastion.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y software-properties-common",
      "sudo apt-add-repository -y --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible",
      "chmod 600 /home/ubuntu/private_key.pem"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"  # Adjust this based on your AMI
      private_key = tls_private_key.instance_key.private_key_pem
      host        = module.bastion.public_ip
    }
  }
}

# Create the Jenkins server
module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name           = "${var.environment}-jenkins"
  ami            = var.ami
  instance_type  = var.instance_type
  key_name       = aws_key_pair.generated_key.key_name
  subnet_id      = module.devops-ninja-vpc.private_subnets[0]
  vpc_security_group_ids = [module.private_instance_sg.security_group_id]

  tags = {
    Name = "${var.environment}-jenkins"
    Environment = var.environment
  }
}

# Create the app instance
module "app" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"
  count = var.app_count
  name           = "${var.environment}-app-${count.index + 1}"
  ami            = var.ami
  instance_type  = var.instance_type
  key_name       = aws_key_pair.generated_key.key_name
  subnet_id      = module.devops-ninja-vpc.private_subnets[count.index % length(module.devops-ninja-vpc.private_subnets)]
  vpc_security_group_ids = [module.private_instance_sg.security_group_id]
  availability_zone = var.azs[count.index % length(var.azs)]
  tags = {
    Name = "${var.environment}-app-${count.index + 1}"
    Environment = var.environment
  }
}

# Create the Windows bastion host
module "windows_bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name           = "${var.environment}-windows-bastion"
  ami            = var.windows_ami
  instance_type  = var.windows_instance_type
  associate_public_ip_address = true
  key_name       = aws_key_pair.generated_key.key_name
  subnet_id      = module.devops-ninja-vpc.public_subnets[0]
  vpc_security_group_ids = [module.bastion_sg.security_group_id]
  root_block_device = [{
    volume_size = 30
    volume_type = "gp2"
  }]
  tags = {
    Name = "${var.environment}-windows-bastion"
    Environment = var.environment
  }
}