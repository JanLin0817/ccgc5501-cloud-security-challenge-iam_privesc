#############################################
# Target EC2 Instance (Private Subnet)
# Has AdministratorAccess role attached
#############################################

resource "aws_instance" "target_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.target_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.target_ec2_profile.name

  # Initial user data - benign
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Target EC2 Instance
    # This instance has a highly privileged IAM role attached
    
    echo "Instance started at $(date)" > /var/log/startup.log
    echo "This is the target EC2 for iam_privesc_by_ec2 scenario" >> /var/log/startup.log
    
    # Install AWS CLI (for when user data is modified)
    yum install -y aws-cli
    
    # Keep the instance running
    echo "Initialization complete" >> /var/log/startup.log
  EOF
  )

  # Enable user data execution on every boot
  user_data_replace_on_change = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"  # IMDSv1 allowed for easier exploitation
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name        = "${local.scenario_name}-target-ec2"
    Role        = "target"
    Description = "Highly privileged EC2 - exploit via user data modification"
  }

  # Ensure the instance profile exists before creating the instance
  depends_on = [
    aws_iam_instance_profile.target_ec2_profile,
    aws_iam_role_policy_attachment.target_ec2_admin
  ]
}

#############################################
# VPC Endpoint for S3 (Gateway Endpoint)
# This allows the private EC2 to reach S3!
# Critical for the attack to work
#############################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "${local.scenario_name}-s3-endpoint"
  }
}

#############################################
# CloudWatch Log Group (for debugging)
#############################################

resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/aws/ec2/${local.scenario_name}"
  retention_in_days = 1

  tags = {
    Name = "${local.scenario_name}-logs"
  }
}
