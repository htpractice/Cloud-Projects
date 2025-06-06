# 💰 Cost Optimization Strategy

## Current Cost Analysis

### 1. **Infrastructure Costs (Estimated Monthly)**
- **EC2 Instances**: 
  - Bastion hosts (2x t3.micro): ~$17/month
  - Jenkins server (1x t3.medium): ~$30/month
  - App instances (2x t3.small): ~$30/month
  - Windows bastion (1x t3.medium): ~$30/month
- **ALB**: ~$22/month + data processing
- **ECR**: ~$0.10/GB/month for storage
- **VPC**: NAT Gateway ~$45/month
- **EBS Storage**: ~$10/month for additional volumes

**Current Estimated Total: ~$184/month**

### 2. **Potential Cost Savings: 40-60% reduction possible**

---

## 🎯 Cost Optimization Strategies

### 1. **Right-Sizing EC2 Instances**

```hcl
# terraform/infra/ec2-optimized.tf
resource "aws_instance" "app_optimized" {
  count                  = var.app_instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.environment == "prod" ? "t3.small" : "t3.micro"
  key_name              = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id             = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  
  # Enable detailed monitoring for cost tracking
  monitoring = true
  
  # Optimized EBS configuration
  root_block_device {
    volume_type = "gp3"  # More cost-effective than gp2
    volume_size = var.environment == "prod" ? 20 : 10
    encrypted   = true
    throughput  = 125    # Default for gp3, cost-effective
    iops        = 3000   # Default for gp3
  }

  tags = {
    Name        = "${var.environment}-app-${count.index + 1}"
    Environment = var.environment
    Project     = "movie-app"
    CostCenter  = "dev-ops"
    AutoShutdown = var.environment != "prod" ? "enabled" : "disabled"
  }
}

# Scheduled scaling for non-production environments
resource "aws_autoscaling_schedule" "scale_down_evening" {
  count                  = var.environment != "prod" ? 1 : 0
  scheduled_action_name  = "scale-down-evening"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence            = "0 18 * * MON-FRI"  # 6 PM on weekdays
  autoscaling_group_name = aws_autoscaling_group.app[0].name
}

resource "aws_autoscaling_schedule" "scale_up_morning" {
  count                  = var.environment != "prod" ? 1 : 0
  scheduled_action_name  = "scale-up-morning"
  min_size               = 1
  max_size               = 2
  desired_capacity       = 1
  recurrence            = "0 8 * * MON-FRI"   # 8 AM on weekdays
  autoscaling_group_name = aws_autoscaling_group.app[0].name
}
```

### 2. **Spot Instances for Development**

```hcl
# terraform/infra/spot-instances.tf
resource "aws_launch_template" "app_spot" {
  count         = var.environment == "dev" ? 1 : 0
  name_prefix   = "${var.environment}-app-spot-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.main.key_name
  
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  
  # Spot instance configuration
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.0104"  # ~50% of on-demand price
    }
  }
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    environment = var.environment
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-app-spot"
      Environment = var.environment
      InstanceType = "spot"
    }
  }
}

resource "aws_autoscaling_group" "app_spot" {
  count               = var.environment == "dev" ? 1 : 0
  name                = "${var.environment}-app-spot-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app_spot[0].id
        version           = "$Latest"
      }
    }
    
    instances_distribution {
      on_demand_percentage                = 0
      spot_allocation_strategy           = "diversified"
      spot_instance_pools                = 2
      spot_max_price                     = "0.0104"
    }
  }
  
  tag {
    key                 = "Name"
    value               = "${var.environment}-app-spot-asg"
    propagate_at_launch = false
  }
}
```

### 3. **Reserved Instances Strategy**

```bash
# scripts/reserved-instances-analysis.sh
#!/bin/bash

# Analyze EC2 usage patterns for Reserved Instance recommendations
aws ce get-reservation-coverage \
  --time-period Start=2023-01-01,End=2023-12-31 \
  --granularity MONTHLY \
  --group-by Type=DIMENSION,Key=INSTANCE_TYPE

# Get RI recommendations
aws ce get-reservation-purchase-recommendation \
  --service EC2-Instance \
  --account-scope PAYER \
  --lookback-period-in-days 60 \
  --term-in-years 1 \
  --payment-option PARTIAL_UPFRONT
```

### 4. **Storage Optimization**

```hcl
# terraform/infra/storage-optimized.tf
# S3 Lifecycle policies for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    id     = "cost_optimization"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555  # 7 years retention
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# EBS Volume optimization
resource "aws_ebs_volume" "app_data" {
  availability_zone = var.availability_zones[0]
  size              = 100
  type              = "gp3"  # More cost-effective than gp2
  throughput        = 125    # Baseline throughput
  iops              = 3000   # Baseline IOPS
  encrypted         = true

  tags = {
    Name = "${var.environment}-app-data"
    Environment = var.environment
    VolumeType = "data"
  }
}
```

### 5. **Network Cost Optimization**

```hcl
# terraform/infra/network-optimized.tf
# VPC Endpoints to reduce NAT Gateway costs
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  tags = {
    Name = "${var.environment}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  
  tags = {
    Name = "${var.environment}-ecr-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  
  tags = {
    Name = "${var.environment}-ecr-api-endpoint"
  }
}

# Conditional NAT Gateway (only for production)
resource "aws_nat_gateway" "main" {
  count         = var.environment == "prod" ? length(var.public_subnet_ids) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]
  
  tags = {
    Name = "${var.environment}-nat-${count.index + 1}"
  }
}

# For non-prod environments, use NAT instances instead
resource "aws_instance" "nat" {
  count                   = var.environment != "prod" ? 1 : 0
  ami                     = data.aws_ami.nat.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.nat.id]
  subnet_id              = var.public_subnet_ids[0]
  source_dest_check      = false
  
  tags = {
    Name = "${var.environment}-nat-instance"
  }
}
```

### 6. **Auto-Shutdown for Development**

```bash
# scripts/auto-shutdown.sh
#!/bin/bash

# Lambda function to automatically stop non-production instances
cat > auto-shutdown-lambda.py << 'EOF'
import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    
    # Get instances with AutoShutdown tag
    response = ec2.describe_instances(
        Filters=[
            {
                'Name': 'tag:AutoShutdown',
                'Values': ['enabled']
            },
            {
                'Name': 'instance-state-name',
                'Values': ['running']
            }
        ]
    )
    
    instance_ids = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            # Check if it's after working hours (6 PM)
            current_hour = datetime.now().hour
            if current_hour >= 18 or current_hour <= 8:
                instance_ids.append(instance['InstanceId'])
    
    if instance_ids:
        ec2.stop_instances(InstanceIds=instance_ids)
        print(f"Stopped instances: {instance_ids}")
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Processed {len(instance_ids)} instances')
    }
EOF

# Create Lambda function
aws lambda create-function \
    --function-name auto-shutdown-instances \
    --runtime python3.9 \
    --role arn:aws:iam::123456789012:role/lambda-execution-role \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://auto-shutdown-lambda.zip
```

### 7. **CloudWatch Cost Monitoring**

```hcl
# terraform/modules/cost-monitoring/main.tf
resource "aws_budgets_budget" "monthly_cost" {
  name         = "${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters {
    tag {
      key = "Environment"
      values = [var.environment]
    }
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}

# CloudWatch Dashboard for cost monitoring
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "${var.environment}-cost-monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"],
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"  # Billing metrics only in us-east-1
          title   = "Estimated Monthly Charges"
          period  = 86400
        }
      }
    ]
  })
}
```

### 8. **Resource Tagging for Cost Allocation**

```hcl
# terraform/infra/tags.tf
locals {
  common_tags = {
    Environment   = var.environment
    Project      = "movie-app"
    Owner        = "devops-team"
    CostCenter   = "engineering"
    Terraform    = "true"
    CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
  }
}

# Apply tags to all resources
resource "aws_instance" "app" {
  count = var.app_instance_count
  # ... other configuration ...
  
  tags = merge(local.common_tags, {
    Name = "${var.environment}-app-${count.index + 1}"
    Role = "application-server"
    InstanceSize = var.instance_type
  })
}

# Cost allocation tags for detailed reporting
resource "aws_organizations_policy" "cost_allocation_tags" {
  name = "cost-allocation-tags"
  type = "TAG_POLICY"
  
  content = jsonencode({
    tags = {
      Environment = {
        tag_key = "Environment"
        enforced_for = ["ec2:instance", "rds:db", "s3:bucket"]
      }
      Project = {
        tag_key = "Project"
        enforced_for = ["ec2:instance", "rds:db", "s3:bucket"]
      }
      CostCenter = {
        tag_key = "CostCenter"
        enforced_for = ["ec2:instance", "rds:db", "s3:bucket"]
      }
    }
  })
}
```

---

## 📊 Cost Monitoring & Alerting

### 1. **Cost and Usage Reporting**

```bash
# scripts/cost-analysis.sh
#!/bin/bash

# Daily cost report
aws ce get-cost-and-usage \
    --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
    --granularity DAILY \
    --metrics BlendedCost \
    --group-by Type=DIMENSION,Key=SERVICE \
    --filter file://cost-filter.json

# Resource utilization report
aws ce get-cost-and-usage \
    --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
    --granularity DAILY \
    --metrics BlendedCost,UsageQuantity \
    --group-by Type=TAG,Key=Environment
```

### 2. **Automated Cost Optimization**

```python
# scripts/cost-optimizer.py
import boto3
import json
from datetime import datetime, timedelta

def identify_idle_resources():
    ec2 = boto3.client('ec2')
    cloudwatch = boto3.client('cloudwatch')
    
    idle_instances = []
    
    # Get all running instances
    response = ec2.describe_instances(
        Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
    )
    
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            
            # Check CPU utilization over last 7 days
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(days=7)
            
            cpu_response = cloudwatch.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='CPUUtilization',
                Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
                StartTime=start_time,
                EndTime=end_time,
                Period=3600,
                Statistics=['Average']
            )
            
            if cpu_response['Datapoints']:
                avg_cpu = sum(point['Average'] for point in cpu_response['Datapoints']) / len(cpu_response['Datapoints'])
                if avg_cpu < 5:  # Less than 5% CPU usage
                    idle_instances.append({
                        'InstanceId': instance_id,
                        'InstanceType': instance['InstanceType'],
                        'AvgCPU': avg_cpu,
                        'Tags': instance.get('Tags', [])
                    })
    
    return idle_instances

def recommend_rightsizing():
    # Implementation for rightsizing recommendations
    pass

if __name__ == "__main__":
    idle_resources = identify_idle_resources()
    print(f"Found {len(idle_resources)} potentially idle instances")
    for resource in idle_resources:
        print(f"Instance {resource['InstanceId']} - Avg CPU: {resource['AvgCPU']:.2f}%")
```

---

## 💡 Quick Wins (Immediate 20-30% savings)

### 1. **Switch to GP3 EBS Volumes**
```bash
# One-time migration script
aws ec2 modify-volume --volume-id vol-xxxxxxxxx --volume-type gp3
```

### 2. **Implement Auto-Shutdown for Dev/Test**
- Save ~70% on non-production compute costs
- Automate with Lambda + CloudWatch Events

### 3. **Use Spot Instances for Development**
- 50-90% savings on compute costs
- Suitable for non-critical workloads

### 4. **Optimize Data Transfer**
- Use VPC endpoints to eliminate NAT Gateway costs
- Implement CloudFront for static assets

---

## 📈 Long-term Strategies (40-60% savings)

### 1. **Reserved Instance Strategy**
- Analyze usage patterns
- Purchase 1-year RIs for stable workloads
- Use Savings Plans for flexible commitment

### 2. **Containerization Optimization**
- Use AWS Fargate for better resource utilization
- Implement ECS/EKS for auto-scaling

### 3. **Serverless Migration**
- Move appropriate workloads to Lambda
- Use API Gateway + Lambda for APIs
- Implement event-driven architecture

---

## 🎯 Cost Optimization Targets

| Environment | Current Cost | Target Cost | Savings |
|-------------|--------------|-------------|---------|
| Development | $60/month | $25/month | 58% |
| Staging | $70/month | $35/month | 50% |
| Production | $150/month | $110/month | 27% |

**Total Monthly Savings: $110 (39% reduction)**

---

## 📊 ROI Analysis

### Investment Required
- **Time**: 40-60 hours for implementation
- **Tools**: Minimal additional cost
- **Training**: 8-16 hours team training

### Expected Returns
- **Year 1 Savings**: $1,320
- **3-Year Savings**: $4,500+
- **Additional Benefits**: Better performance, improved monitoring

**ROI: 300%+ over 3 years** 