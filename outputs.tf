#############################################
# Outputs
#############################################

output "scenario_info" {
  description = "Scenario information"
  value = {
    scenario_name = local.scenario_name
    aws_region    = var.aws_region
    account_id    = data.aws_caller_identity.current.account_id
  }
}

output "dev_user_credentials" {
  description = "Starting credentials for dev_user"
  value = {
    username          = aws_iam_user.dev_user.name
    access_key_id     = aws_iam_access_key.dev_user_key.id
    secret_access_key = aws_iam_access_key.dev_user_key.secret
  }
  sensitive = true
}

output "target_ec2_info" {
  description = "Information about the target EC2 instance"
  value = {
    instance_id       = aws_instance.target_ec2.id
    private_ip        = aws_instance.target_ec2.private_ip
    iam_role          = aws_iam_role.target_ec2_role.name
    instance_profile  = aws_iam_instance_profile.target_ec2_profile.name
    subnet_id         = aws_subnet.private.id
    security_group_id = aws_security_group.target_ec2.id
  }
}

output "exfil_bucket" {
  description = "S3 bucket for credential exfiltration"
  value = {
    bucket_name = aws_s3_bucket.exfil_bucket.id
    bucket_arn  = aws_s3_bucket.exfil_bucket.arn
  }
}

output "public_subnet_info" {
  description = "Public subnet info for launching attacker EC2"
  value = {
    subnet_id         = aws_subnet.public.id
    security_group_id = aws_security_group.attacker_ec2.id
  }
}

output "attacker_ec2_role" {
  description = "IAM role for attacker EC2 instance"
  value = {
    role_name            = aws_iam_role.attacker_ec2_role.name
    instance_profile_arn = aws_iam_instance_profile.attacker_ec2_profile.arn
    instance_profile_name = aws_iam_instance_profile.attacker_ec2_profile.name
  }
}

output "ami_id" {
  description = "AMI ID for launching EC2 instances"
  value       = data.aws_ami.amazon_linux.id
}

output "goal" {
  description = "Scenario goal"
  value       = "Escalate privileges from dev_user to retrieve the flag from s3://${aws_s3_bucket.flag_bucket.id}/flag.txt"
}

#############################################
# Start File Content
#############################################

output "start_txt" {
  description = "Content for start.txt file"
  value       = <<-EOF
    
    ╔══════════════════════════════════════════════════════════════╗
    ║            IAM Privilege Escalation by EC2                   ║
    ║                  User Data Modification                       ║
    ╚══════════════════════════════════════════════════════════════╝
    
    SCENARIO: ${local.scenario_name}
    REGION: ${var.aws_region}
    
    ══════════════════════════════════════════════════════════════════
    STARTING CREDENTIALS (dev_user)
    ══════════════════════════════════════════════════════════════════
    
    AWS_ACCESS_KEY_ID: ${aws_iam_access_key.dev_user_key.id}
    AWS_SECRET_ACCESS_KEY: ${aws_iam_access_key.dev_user_key.secret}
    
    Configure with:
      aws configure --profile dev_user
    
    ══════════════════════════════════════════════════════════════════
    GOAL
    ══════════════════════════════════════════════════════════════════
    
    Retrieve the flag from:
      s3://${aws_s3_bucket.flag_bucket.id}/flag.txt
    
    ══════════════════════════════════════════════════════════════════
    HINTS
    ══════════════════════════════════════════════════════════════════
    
    1. You start as dev_user with limited permissions
    2. There is an EC2 instance with a highly privileged IAM role
    3. The EC2 is in a private subnet WITHOUT SSM access
    4. Think about what happens when an EC2 instance boots...
    5. User data scripts run as root on first boot
    6. There's an S3 bucket you can access for data exfiltration
    7. IMPORTANT: Regular #!/bin/bash only runs on FIRST boot!
       Use #cloud-boothook to run on every boot (after stop/start)
    
    ══════════════════════════════════════════════════════════════════
    USEFUL INFO
    ══════════════════════════════════════════════════════════════════
    
    Target EC2 Instance ID: ${aws_instance.target_ec2.id}
    Exfiltration Bucket: ${aws_s3_bucket.exfil_bucket.id}
    Public Subnet ID: ${aws_subnet.public.id}
    Public Security Group: ${aws_security_group.attacker_ec2.id}
    Attacker Instance Profile: ${aws_iam_instance_profile.attacker_ec2_profile.name}
    AMI ID: ${data.aws_ami.amazon_linux.id}
    
    Good luck! 🐐☁️
    
  EOF
  sensitive = true
}
