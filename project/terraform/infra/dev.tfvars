#For windows bation default ami image and instance type is defined.
vpc_cidr = "10.1.0.0/16"
azs = ["us-east-1a", "us-east-1b"]
environment = "dev"
private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
public_subnets = ["10.1.10.0/24", "10.1.11.0/24"]
instance_type = "t2.micro"
ami = "ami-04b4f1a9cf54c11d0"
app_count = 2
windows_ami = "ami-07fa5275316057f54"
windows_instance_type = "t3.micro"
my_local_IP = "182.70.25.32/32"