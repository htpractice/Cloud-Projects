# 🔐 Security Improvements

## Current Security Issues

### 1. **Hardcoded Secrets**
- AWS credentials in code/config files
- Database passwords in docker-compose
- Private keys stored in repositories

### 2. **Overprivileged IAM Roles**
- Broad permissions instead of least privilege
- No resource-specific restrictions

### 3. **Network Security Gaps**
- Missing encryption in transit
- Insufficient security group restrictions

---

## 🛡️ Recommended Security Enhancements

### 1. **Secrets Management with AWS Secrets Manager**

```hcl
# terraform/modules/secrets/main.tf
resource "aws_secretsmanager_secret" "app_secrets" {
  name = "${var.environment}-movie-app-secrets"
  description = "Application secrets for movie app"
  
  tags = {
    Environment = var.environment
    Application = "movie-app"
  }
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    mongodb_uri = var.mongodb_uri
    jwt_secret = var.jwt_secret
    api_key = var.api_key
  })
}
```

### 2. **Enhanced IAM Roles with Least Privilege**

```hcl
# terraform/infra/iam-enhanced.tf
resource "aws_iam_role" "app_role_enhanced" {
  name = "${var.environment}-app-role-enhanced"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "app_policy_enhanced" {
  name = "${var.environment}-app-policy-enhanced"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [
          "arn:aws:ecr:${var.aws_region}:${var.aws_account}:repository/${var.environment}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account}:secret:${var.environment}-*"
        ]
      }
    ]
  })
}
```

### 3. **Security Groups Hardening**

```hcl
# terraform/infra/security-groups-enhanced.tf
resource "aws_security_group" "app_sg_enhanced" {
  name_prefix = "${var.environment}-app-enhanced-"
  vpc_id      = var.vpc_id

  # Allow HTTPS only (no HTTP)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Application port from ALB only
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SSH from bastion only
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-app-sg-enhanced"
  }
}
```

### 4. **SSL/TLS Configuration**

```hcl
# terraform/infra/ssl-certificate.tf
resource "aws_acm_certificate" "app_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.environment}-app-certificate"
  }
}

# ALB Listener with SSL
resource "aws_lb_listener" "app_https" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.app_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
```

### 5. **Enhanced Docker Security**

```dockerfile
# movie-app/server/Dockerfile.secure
FROM node:18-alpine AS base

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY --chown=nextjs:nodejs . .

# Switch to non-root user
USER nextjs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000
CMD ["node", "index.js"]
```

### 6. **Secrets in Jenkins Pipeline**

```groovy
// jenkins/Jenkinsfile.secure
pipeline {
    agent any
    
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }
    
    stages {
        stage('Get Secrets') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'aws-account-id', variable: 'AWS_ACCOUNT'),
                        string(credentialsId: 'ecr-region', variable: 'ECR_REGION')
                    ]) {
                        env.AWS_ACCOUNT = AWS_ACCOUNT
                        env.ECR_REGION = ECR_REGION
                    }
                }
            }
        }
        
        stage('Docker Login') {
            steps {
                sh '''
                    aws ecr get-login-password --region ${ECR_REGION} | \
                    docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com
                '''
            }
        }
    }
}
```

### 7. **Environment Variables Security**

```yaml
# ansible/roles/app-config/tasks/main.yml
- name: Create secure environment file
  template:
    src: app.env.j2
    dest: /opt/movie-app/.env
    mode: '0600'
    owner: ubuntu
    group: ubuntu
  vars:
    mongodb_uri: "{{ lookup('aws_ssm', '/movie-app/dev/mongodb-uri', region=aws_region) }}"
    jwt_secret: "{{ lookup('aws_ssm', '/movie-app/dev/jwt-secret', region=aws_region) }}"

- name: Set up systemd service for app
  template:
    src: movie-app.service.j2
    dest: /etc/systemd/system/movie-app.service
    mode: '0644'
  notify: restart movie-app
```

---

## 🔍 Security Audit Checklist

### Infrastructure Security
- [ ] All secrets moved to AWS Secrets Manager/Parameter Store
- [ ] IAM roles follow least privilege principle
- [ ] Security groups restrict access to necessary ports only
- [ ] SSL/TLS encryption enabled for all external communications
- [ ] VPC Flow Logs enabled
- [ ] CloudTrail logging enabled

### Application Security
- [ ] Docker containers run as non-root users
- [ ] Application dependencies updated to latest secure versions
- [ ] Input validation implemented
- [ ] SQL injection protection in place
- [ ] XSS protection headers configured
- [ ] CORS properly configured

### Access Control
- [ ] MFA enabled for all admin accounts
- [ ] SSH key rotation policy in place
- [ ] Bastion host access properly logged
- [ ] Service accounts have minimal permissions
- [ ] Regular access reviews conducted

---

## 📈 Implementation Priority

### Phase 1 (Week 1) - Critical
1. Move hardcoded secrets to AWS Secrets Manager
2. Update IAM roles with least privilege
3. Enable SSL/TLS for ALB

### Phase 2 (Week 2) - High Priority
1. Harden security groups
2. Implement container security best practices
3. Set up VPC Flow Logs and CloudTrail

### Phase 3 (Week 3) - Medium Priority
1. Implement comprehensive logging
2. Set up automated security scanning
3. Create security incident response plan

---

## 💰 Cost Impact
- AWS Secrets Manager: ~$0.40/secret/month
- SSL Certificate (ACM): Free
- VPC Flow Logs: ~$0.50/GB
- CloudTrail: First trail free, additional ~$2/100k events

**Total Estimated Monthly Cost: $10-20 (depending on usage)** 