# IAM Privilege Escalation by EC2

## Scenario Overview

| Attribute | Value |
|-----------|-------|
| Difficulty | Medium |
| Attack Vector | EC2 User Data Modification |
| Starting User | dev_user (limited IAM permissions) |
| Goal | Retrieve flag from protected S3 bucket |

## Description

Starting as the IAM user `dev_user` with limited permissions, the attacker discovers they can stop, modify, and start an EC2 instance in a private subnet. The target EC2 has an AdministratorAccess IAM role attached.

Since the EC2 is in a private subnet **without SSM VPC endpoints**, the attacker cannot use SSM to run commands. However, by modifying the instance's user data and rebooting it, the attacker can inject a malicious script that exfiltrates the EC2's IAM role credentials to an S3 bucket.

With the stolen admin credentials, the attacker can access the protected flag bucket.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           AWS Account                            │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                         VPC                                  ││
│  │                                                              ││
│  │  ┌─────────────────────┐    ┌─────────────────────────────┐ ││
│  │  │   Public Subnet     │    │      Private Subnet         │ ││
│  │  │                     │    │                             │ ││
│  │  │  ┌───────────────┐  │    │  ┌───────────────────────┐  │ ││
│  │  │  │ Attacker EC2  │  │    │  │     Target EC2        │  │ ││
│  │  │  │ (optional)    │  │    │  │  ┌─────────────────┐  │  │ ││
│  │  │  └───────────────┘  │    │  │  │ Admin IAM Role  │  │  │ ││
│  │  │                     │    │  │  └─────────────────┘  │  │ ││
│  │  └─────────────────────┘    │  └───────────────────────┘  │ ││
│  │           │                 │            │                │ ││
│  │           │ IGW             │            │ S3 Endpoint    │ ││
│  │           ▼                 │            ▼                │ ││
│  └───────────┬─────────────────┴────────────┬────────────────┘ ││
│              │                              │                   │
│  ┌───────────▼───────────┐    ┌─────────────▼─────────────────┐│
│  │      Internet         │    │         S3 Buckets            ││
│  │                       │    │  ┌─────────┐ ┌─────────────┐  ││
│  └───────────────────────┘    │  │ Exfil   │ │ Flag Bucket │  ││
│                               │  │ Bucket  │ │ (Protected) │  ││
│                               │  └─────────┘ └─────────────┘  ││
│                               └───────────────────────────────┘│
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐│
│  │                    IAM Resources                            ││
│  │  ┌──────────────┐  ┌─────────────────────────────────────┐ ││
│  │  │   dev_user   │  │ EC2 Target Role (AdministratorAccess)│ ││
│  │  │  (starting)  │  │            (the prize!)              │ ││
│  │  └──────────────┘  └─────────────────────────────────────┘ ││
│  └────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## Resources Created

| Resource | Description |
|----------|-------------|
| VPC | Virtual Private Cloud with public and private subnets |
| EC2 (Target) | Private subnet, AdministratorAccess role |
| S3 (Exfil) | Bucket for credential exfiltration |
| S3 (Flag) | Protected bucket containing the flag |
| IAM User | dev_user with limited EC2 permissions |
| IAM Role | Highly privileged EC2 role |
| VPC Endpoint | S3 gateway endpoint for private subnet |

## Deployment

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy
terraform apply

# View outputs (including credentials)
terraform output -json

# View start.txt content
terraform output -raw start_txt
```

## Destruction

```bash
terraform destroy -auto-approve
```