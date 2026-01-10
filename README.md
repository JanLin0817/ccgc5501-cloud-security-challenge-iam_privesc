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

## Attack Path

```
dev_user (limited)
    │
    ├── 1. Enumerate permissions
    │
    ├── 2. Discover target EC2 with admin role
    │
    ├── 3. Stop the target instance
    │
    ├── 4. Modify user data with credential exfiltration script
    │
    ├── 5. Start the instance
    │
    ├── 6. Wait for boot, retrieve creds from S3
    │
    └── 7. Use admin credentials to get flag
            │
            ▼
    Flag Retrieved! 🚩
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

## Permissions Granted to dev_user

- `ec2:Describe*` - View EC2 resources
- `ec2:StopInstances` - Stop the target EC2
- `ec2:StartInstances` - Start the target EC2
- `ec2:ModifyInstanceAttribute` (userData only) - Modify user data
- `s3:GetObject`, `s3:ListBucket` - Read from exfil bucket
- `iam:Get*`, `iam:List*` - Enumerate IAM
- `ec2:RunInstances` - Launch EC2 in public subnet (optional path)
- `ec2:CreateKeyPair` - Create SSH key pairs

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

## Key Vulnerabilities Demonstrated

1. **Overly Permissive EC2 Permissions** - Allowing user data modification enables code injection
2. **IMDSv1 Enabled** - Credentials can be retrieved without a session token
3. **Highly Privileged EC2 Role** - AdministratorAccess attached to EC2
4. **Lack of Monitoring** - No CloudTrail alerts on ModifyInstanceAttribute

## Important Technical Note

**User data execution behavior:**
- Regular `#!/bin/bash` user data only runs on the **first boot** of an instance
- After stop/start, cloud-init won't re-run regular scripts (it caches completion state)
- To run on every boot, use `#cloud-boothook` at the start of the script
- This is critical knowledge for exploiting this attack vector!

## Mitigations

1. **Require IMDSv2** - Prevents simple credential theft
2. **Restrict ModifyInstanceAttribute** - Don't allow user data changes
3. **Use Least Privilege** - EC2 roles should have minimal permissions
4. **Monitor with CloudTrail** - Alert on suspicious EC2 attribute modifications
5. **Use AWS Config** - Detect changes to EC2 configurations
