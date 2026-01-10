#############################################
# Starting IAM User: dev_user
# This is the user the attacker starts with
#############################################

resource "aws_iam_user" "dev_user" {
  name = "${local.scenario_name}-dev-user"
  path = "/"

  tags = {
    Name        = "${local.scenario_name}-dev-user"
    Description = "Starting user for iam_privesc_by_ec2 scenario"
  }
}

resource "aws_iam_access_key" "dev_user_key" {
  user = aws_iam_user.dev_user.name
}

#############################################
# Policy for dev_user
# Allows EC2 user data modification attack
#############################################

resource "aws_iam_policy" "dev_user_policy" {
  name        = "${local.scenario_name}-dev-user-policy"
  description = "Policy for dev_user in iam_privesc_by_ec2 scenario"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2DescribeAll"
        Effect = "Allow"
        Action = [
          "ec2:Describe*"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2StopStartTarget"
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:StartInstances"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.target_ec2.id}"
      },
      {
        Sid    = "EC2ModifyUserData"
        Effect = "Allow"
        Action = [
          "ec2:ModifyInstanceAttribute"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.target_ec2.id}"
      },
      {
        Sid    = "S3ExfilBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.exfil_bucket.arn,
          "${aws_s3_bucket.exfil_bucket.arn}/*"
        ]
      },
      {
        Sid    = "IAMReadOnly"
        Effect = "Allow"
        Action = [
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "STSGetCallerIdentity"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2CreateKeyPair"
        Effect = "Allow"
        Action = [
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2RunInstancesPublicSubnet"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = [
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/${aws_subnet.public.id}",
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/${aws_security_group.attacker_ec2.id}",
          "arn:aws:ec2:${var.aws_region}::image/*",
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key-pair/*"
        ]
      },
      {
        Sid    = "EC2PassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = aws_iam_role.attacker_ec2_role.arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
      {
        Sid    = "EC2TerminateOwnInstances"
        Effect = "Allow"
        Action = [
          "ec2:TerminateInstances"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Owner" = aws_iam_user.dev_user.name
          }
        }
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "dev_user_policy_attachment" {
  user       = aws_iam_user.dev_user.name
  policy_arn = aws_iam_policy.dev_user_policy.arn
}
