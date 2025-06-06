# 📊 Monitoring & Observability

## Current Monitoring Gaps

### 1. **No Application Monitoring**
- No visibility into application performance
- No error tracking or alerting
- No user experience monitoring

### 2. **Infrastructure Blind Spots**
- No resource utilization monitoring
- No network traffic analysis
- No automated alerting for failures

### 3. **Log Management Issues**
- Logs scattered across instances
- No centralized log aggregation
- No log-based alerting

---

## 🔍 Comprehensive Monitoring Strategy

### 1. **CloudWatch Enhanced Monitoring**

```hcl
# terraform/modules/monitoring/cloudwatch.tf
resource "aws_cloudwatch_dashboard" "movie_app_dashboard" {
  dashboard_name = "${var.environment}-movie-app-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app_alb.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ALB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app[0].id],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."],
            [".", "DiskReadOps", ".", "."],
            [".", "DiskWriteOps", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 Instance Metrics"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.app[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.app_alb.arn_suffix
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-movie-app-alerts"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```

### 2. **ELK Stack for Centralized Logging**

```hcl
# terraform/modules/monitoring/elasticsearch.tf
resource "aws_elasticsearch_domain" "movie_app_logs" {
  domain_name           = "${var.environment}-movie-app-logs"
  elasticsearch_version = "7.10"

  cluster_config {
    instance_type  = "t3.small.elasticsearch"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 20
  }

  vpc_options {
    subnet_ids         = [var.private_subnet_ids[0]]
    security_group_ids = [aws_security_group.elasticsearch.id]
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "es:*"
        Principal = "*"
        Effect = "Allow"
        Resource = "arn:aws:es:${var.aws_region}:${var.aws_account}:domain/${var.environment}-movie-app-logs/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = [var.vpc_cidr]
          }
        }
      }
    ]
  })

  tags = {
    Domain = "${var.environment}-movie-app-logs"
  }
}

resource "aws_security_group" "elasticsearch" {
  name_prefix = "${var.environment}-elasticsearch-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-elasticsearch-sg"
  }
}
```

### 3. **Application Performance Monitoring with Grafana**

```yaml
# docker/monitoring/docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards

  node_exporter:
    image: prom/node-exporter:latest
    container_name: node_exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro

volumes:
  prometheus_data:
  grafana_data:
```

### 4. **Application Metrics Integration**

```javascript
// movie-app/server/middleware/metrics.js
const client = require('prom-client');

// Create a Registry to register the metrics
const register = new client.Registry();

// Add a default label which is added to all metrics
register.setDefaultLabels({
  app: 'movie-app-server'
});

// Enable the collection of default metrics
client.collectDefaultMetrics({ register });

// Create custom metrics
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [1, 5, 15, 50, 100, 500, 1000]
});

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const activeConnections = new client.Gauge({
  name: 'active_connections',
  help: 'Number of active connections'
});

// Register the custom metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(activeConnections);

// Middleware to track HTTP requests
const trackHttpRequests = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    const route = req.route ? req.route.path : req.path;
    
    httpRequestDuration
      .labels(req.method, route, res.statusCode.toString())
      .observe(duration);
    
    httpRequestsTotal
      .labels(req.method, route, res.statusCode.toString())
      .inc();
  });
  
  next();
};

module.exports = {
  register,
  trackHttpRequests,
  activeConnections
};
```

### 5. **Structured Logging with Winston**

```javascript
// movie-app/server/config/logger.js
const winston = require('winston');
const { ElasticsearchTransport } = require('winston-elasticsearch');

const esTransportOpts = {
  level: 'info',
  clientOpts: {
    node: process.env.ELASTICSEARCH_URL || 'http://localhost:9200'
  },
  index: 'movie-app-logs'
};

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { 
    service: 'movie-app-server',
    environment: process.env.NODE_ENV || 'development'
  },
  transports: [
    new winston.transports.File({ 
      filename: 'logs/error.log', 
      level: 'error' 
    }),
    new winston.transports.File({ 
      filename: 'logs/combined.log' 
    }),
    new ElasticsearchTransport(esTransportOpts)
  ]
});

// If not in production, log to console as well
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

module.exports = logger;
```

### 6. **Health Check Endpoints**

```javascript
// movie-app/server/routes/health.js
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const logger = require('../config/logger');

// Basic health check
router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Detailed health check
router.get('/health/detailed', async (req, res) => {
  const health = {
    status: 'UP',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    checks: {}
  };

  // Database health check
  try {
    if (mongoose.connection.readyState === 1) {
      health.checks.database = {
        status: 'UP',
        responseTime: await checkDatabaseResponseTime()
      };
    } else {
      health.checks.database = {
        status: 'DOWN',
        error: 'Database connection not established'
      };
      health.status = 'DOWN';
    }
  } catch (error) {
    health.checks.database = {
      status: 'DOWN',
      error: error.message
    };
    health.status = 'DOWN';
  }

  // Memory usage check
  const memUsage = process.memoryUsage();
  health.checks.memory = {
    status: memUsage.heapUsed / memUsage.heapTotal < 0.9 ? 'UP' : 'WARN',
    heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)} MB`,
    heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)} MB`,
    usage: `${Math.round((memUsage.heapUsed / memUsage.heapTotal) * 100)}%`
  };

  const statusCode = health.status === 'UP' ? 200 : 503;
  res.status(statusCode).json(health);
});

async function checkDatabaseResponseTime() {
  const start = Date.now();
  await mongoose.connection.db.admin().command({ ismaster: 1 });
  return Date.now() - start;
}

module.exports = router;
```

### 7. **Ansible Monitoring Setup**

```yaml
# ansible/roles/monitoring/tasks/main.yml
- name: Install Docker Compose for monitoring stack
  pip:
    name: docker-compose
    state: present

- name: Create monitoring directory
  file:
    path: /opt/monitoring
    state: directory
    owner: ubuntu
    group: ubuntu
    mode: '0755'

- name: Copy monitoring docker-compose file
  template:
    src: docker-compose.monitoring.yml.j2
    dest: /opt/monitoring/docker-compose.yml
    owner: ubuntu
    group: ubuntu
    mode: '0644'

- name: Copy Prometheus configuration
  template:
    src: prometheus.yml.j2
    dest: /opt/monitoring/prometheus/prometheus.yml
    owner: ubuntu
    group: ubuntu
    mode: '0644'

- name: Start monitoring stack
  docker_compose:
    project_src: /opt/monitoring
    state: present
  become: yes

- name: Install CloudWatch agent
  get_url:
    url: https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    dest: /tmp/amazon-cloudwatch-agent.rpm

- name: Install CloudWatch agent package
  yum:
    name: /tmp/amazon-cloudwatch-agent.rpm
    state: present
  become: yes

- name: Configure CloudWatch agent
  template:
    src: cloudwatch-config.json.j2
    dest: /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    owner: root
    group: root
    mode: '0644'
  become: yes

- name: Start CloudWatch agent
  systemd:
    name: amazon-cloudwatch-agent
    state: started
    enabled: yes
  become: yes
```

---

## 📈 Monitoring Dashboard Examples

### 1. **Grafana Application Dashboard**
- Request rate and response times
- Error rates by endpoint
- Database connection pool status
- Memory and CPU usage
- Active user sessions

### 2. **Infrastructure Dashboard**
- EC2 instance metrics (CPU, memory, disk, network)
- ALB performance and health
- RDS/MongoDB performance
- Auto Scaling group metrics
- VPC flow logs analysis

### 3. **Business Metrics Dashboard**
- User registrations and logins
- Movie searches and views
- API usage patterns
- Performance by geographic region
- Revenue/usage correlation

---

## 🚨 Alerting Strategy

### Critical Alerts (Immediate Response)
- Application down (5XX errors > threshold)
- Database connection failures
- High CPU/Memory usage (>90%)
- Disk space critical (<10%)

### Warning Alerts (Within 30 minutes)
- Response time degradation
- Error rate increase
- Unusual traffic patterns
- Certificate expiration warnings

### Info Alerts (Daily Summary)
- Performance summary
- Resource utilization trends
- Security events summary
- Cost optimization opportunities

---

## 📊 Implementation Timeline

### Week 1: Foundation
- Set up CloudWatch dashboards and basic alarms
- Implement health check endpoints
- Configure basic logging

### Week 2: Advanced Monitoring
- Deploy ELK stack for log aggregation
- Set up Prometheus and Grafana
- Implement application metrics

### Week 3: Alerting & Optimization
- Configure comprehensive alerting
- Set up automated responses
- Optimize dashboard layouts

### Week 4: Documentation & Training
- Create monitoring runbooks
- Train team on dashboards and alerts
- Establish on-call procedures

---

## 💰 Cost Estimation

### AWS CloudWatch
- Custom metrics: ~$0.30/metric/month
- Dashboards: ~$3/dashboard/month
- Alarms: ~$0.10/alarm/month
- Logs: ~$0.50/GB ingested

### Elasticsearch
- t3.small instance: ~$25/month
- 20GB storage: ~$2/month

### Self-hosted Monitoring (Grafana/Prometheus)
- Additional EC2 instance: ~$10-20/month

**Total Estimated Cost: $50-80/month** 