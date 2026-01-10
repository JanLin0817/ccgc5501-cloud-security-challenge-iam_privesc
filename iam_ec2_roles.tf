#############################################
# IAM Role for Target EC2 (Highly Privileged)
# This is what the attacker wants to steal!
#############################################

resource "aws_iam_role" "target_ec2_role" {
  name = "${local.scenario_name}-target-ec2-role"

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

  tags = {
    Name = "${local.scenario_name}-target-ec2-role"
  }
}

# Attach AdministratorAccess to target EC2 role (the prize!)
resource "aws_iam_role_policy_attachment" "target_ec2_admin" {
  role       = aws_iam_role.target_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "target_ec2_profile" {
  name = "${local.scenario_name}-target-ec2-profile"
  role = aws_iam_role.target_ec2_role.name
}

#############################################
# IAM Role for Attacker EC2 (Limited)
#############################################

resource "aws_iam_role" "attacker_ec2_role" {
  name = "${local.scenario_name}-attacker-ec2-role"

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

  tags = {
    Name = "${local.scenario_name}-attacker-ec2-role"
  }
}

# Attacker EC2 can read from the exfil bucket
resource "aws_iam_role_policy" "attacker_ec2_policy" {
  name = "${local.scenario_name}-attacker-ec2-policy"
  role = aws_iam_role.attacker_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ExfilBucketRead"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.exfil_bucket.arn,
          "${aws_s3_bucket.exfil_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "attacker_ec2_profile" {
  name = "${local.scenario_name}-attacker-ec2-profile"
  role = aws_iam_role.attacker_ec2_role.name
}
