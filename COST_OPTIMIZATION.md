# Cost Optimization Guide

This document explains how this deployment maximizes cost savings while maintaining functionality.

## Cost Breakdown

### EC2 Instance Costs

#### t3.micro (Default)
| Type | Hourly Cost | Daily Cost | Monthly Cost (730 hrs) | Annual Cost |
|------|-------------|------------|------------------------|-------------|
| On-Demand | $0.0104 | $0.25 | $7.59 | $91.08 |
| Spot Instance | ~$0.003 | ~$0.07 | ~$2.19 | ~$26.28 |
| **Savings** | **71%** | **71%** | **71%** | **71%** |

#### t3.small (Alternative)
| Type | Hourly Cost | Daily Cost | Monthly Cost (730 hrs) | Annual Cost |
|------|-------------|------------|------------------------|-------------|
| On-Demand | $0.0208 | $0.50 | $15.18 | $182.16 |
| Spot Instance | ~$0.007 | ~$0.17 | ~$5.11 | ~$61.32 |
| **Savings** | **66%** | **66%** | **66%** | **66%** |

### Additional AWS Costs

| Resource | Estimated Monthly Cost |
|----------|------------------------|
| VPC | $0 (free) |
| Internet Gateway | $0 (free) |
| Security Group | $0 (free) |
| Route Table | $0 (free) |
| Subnet | $0 (free) |
| Public IP (EIP) | $0 (while attached) |
| Data Transfer OUT | ~$0.09/GB (first 10TB) |

### Total Monthly Cost Estimate

**Using t3.micro Spot Instance:**
- EC2 Instance: ~$2.19
- Data Transfer (assuming 10GB): ~$0.90
- **Total: ~$3.09/month**

**Using t3.micro On-Demand:**
- EC2 Instance: ~$7.59
- Data Transfer (assuming 10GB): ~$0.90
- **Total: ~$8.49/month**

## Cost Optimization Features

### 1. Spot Instances (Default)

**How it works:**
- Uses spare AWS EC2 capacity at up to 90% discount
- May be interrupted with 2-minute notice
- Best for non-critical, fault-tolerant workloads

**Configuration:**
```hcl
use_spot_instance = true
spot_price        = "0.0104"  # Maximum price willing to pay
```

**Tradeoffs:**
- ✅ 70% cost savings
- ✅ Same instance performance
- ⚠️ May be interrupted if AWS needs capacity
- ⚠️ Interruption rate depends on instance type and region

### 2. Right-Sized Instance Type

**t3.micro Specifications:**
- 2 vCPUs
- 1 GB Memory
- Up to 5 Gbps network
- Burstable CPU performance

**Why t3.micro is sufficient for Atlantis:**
- Atlantis is primarily I/O bound (Git operations)
- Low memory footprint for single-user or small team usage
- T3 instances provide burst credits for occasional high CPU usage
- Can handle 10-50 repositories comfortably

**When to scale up to t3.small:**
- Supporting 50+ repositories
- Heavy concurrent PR activity
- Complex Terraform plans with large state files
- Multiple simultaneous applies

### 3. Single Instance Deployment

**Architecture choice:**
- One EC2 instance in a public subnet
- No load balancer (saves ~$18/month)
- No NAT Gateway (saves ~$32/month)
- Direct internet connectivity

**Tradeoffs:**
- ✅ Minimal cost (~$3/month vs ~$53/month with ALB/NAT)
- ✅ Simple architecture
- ⚠️ No automatic failover
- ⚠️ Single point of failure
- ⚠️ No built-in SSL/TLS termination

### 4. Spot Instance Best Practices

**Minimize interruptions:**
1. Use `t3.micro` - historically low interruption rates (<5%)
2. Set max price at on-demand price for lowest interruption risk
3. Monitor interruption notices (2-minute warning)
4. Use CloudWatch for alerting

**Handle interruptions gracefully:**
1. Atlantis state is stored in `/var/lib/atlantis` (configure EBS backup)
2. Consider using `persistent` spot requests for auto-restart
3. Implement health checks and auto-recovery

**Configuration for production:**
```hcl
# For higher availability in production
use_spot_instance = false  # Use on-demand

# OR use persistent spot requests
# Modify main.tf spot_instance_type = "persistent"
```

## Additional Cost Optimization Tips

### 1. Reserved Instances
If running 24/7 for 1+ years, consider Reserved Instances:
- 1-year commitment: ~40% savings
- 3-year commitment: ~60% savings
- Can be applied to t3.micro on-demand instances

### 2. Instance Scheduler
Stop instance during off-hours:
```bash
# Example: Stop at night, start in morning
# Saves ~50% if only running 12 hours/day
```

### 3. EBS Volume Optimization
The default root volume is typically 8-10GB:
- Use GP3 instead of GP2 (20% cheaper for same performance)
- Size appropriately (delete old Terraform states)
- Enable EBS snapshots only when needed

### 4. Data Transfer Costs
Minimize egress charges:
- Place Atlantis in same region as most repositories
- Use VPC endpoints for AWS services (avoid internet charges)
- Cache dependencies when possible

### 5. CloudWatch Logs
Keep log retention short:
- Default: 7 days (usually sufficient)
- Avoid "Never Expire" setting
- Export old logs to S3 if long-term retention needed

## Cost Monitoring

### Set Up Billing Alerts

1. AWS Budgets (free tier):
   - Set budget for $5/month
   - Alert at 80% and 100%

2. Cost Explorer:
   - Review costs weekly
   - Filter by resource tags
   - Identify unexpected charges

### Track with Tags
All resources are tagged with:
```hcl
tags = {
  Project     = "Atlantis-Bootstrap"
  Environment = var.environment
  ManagedBy   = "Terraform"
}
```

## Comparison with Alternatives

### Atlantis on Other Platforms

| Platform | Monthly Cost | Pros | Cons |
|----------|--------------|------|------|
| **AWS EC2 (this)** | **~$3** | Cheapest, full control | Manual setup |
| AWS ECS Fargate | ~$12 | Serverless, auto-scaling | More expensive |
| AWS EKS | ~$75+ | Production-ready, HA | Overkill for small teams |
| Terraform Cloud | $0-20 | Managed, no infra | Limited free tier |
| GitHub Actions | $0-21 | Native integration | Per-minute billing |
| Self-hosted VM | Varies | Full control | Manual management |

## Recommendations by Use Case

### Individual Developer / Learning
```hcl
instance_type     = "t3.micro"
use_spot_instance = true
```
**Cost: ~$3/month**

### Small Team (2-10 developers)
```hcl
instance_type     = "t3.micro"
use_spot_instance = true
```
**Cost: ~$3/month**

### Medium Team (10-50 developers)
```hcl
instance_type     = "t3.small"
use_spot_instance = true
```
**Cost: ~$5/month**

### Production / Large Team (50+ developers)
```hcl
instance_type     = "t3.small" or "t3.medium"
use_spot_instance = false  # Use on-demand or Reserved Instance
# Add: Application Load Balancer + SSL
# Add: Auto Scaling Group for HA
```
**Cost: ~$30-50/month**

## Summary

This deployment achieves maximum cost savings through:

1. ✅ Spot Instances: 70% savings on compute
2. ✅ Right-sized instance: t3.micro for most use cases
3. ✅ Minimal infrastructure: No unnecessary resources
4. ✅ No managed services: Direct EC2 vs ECS/EKS
5. ✅ Smart defaults: Production-ready with cost optimizations

**Total Savings vs Traditional Setup:**
- vs On-Demand EC2 with ALB: 94% savings ($3 vs $53/month)
- vs EKS: 96% savings ($3 vs $75/month)
- vs Managed Solutions: 85% savings ($3 vs $20/month)

**Annual Savings: ~$600-900/year**
