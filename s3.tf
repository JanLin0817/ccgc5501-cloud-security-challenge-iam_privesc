#############################################
# S3 Bucket for Credential Exfiltration
# Target EC2 will write credentials here on boot
#############################################

resource "aws_s3_bucket" "exfil_bucket" {
  bucket        = "${local.scenario_name}-exfil-bucket"
  force_destroy = true

  tags = {
    Name = "${local.scenario_name}-exfil-bucket"
  }
}

resource "aws_s3_bucket_versioning" "exfil_bucket_versioning" {
  bucket = aws_s3_bucket.exfil_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "exfil_bucket_public_access" {
  bucket = aws_s3_bucket.exfil_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#############################################
# S3 Bucket Policy
# Allow target EC2 role to write credentials
#############################################

resource "aws_s3_bucket_policy" "exfil_bucket_policy" {
  bucket = aws_s3_bucket.exfil_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowTargetEC2Write"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.target_ec2_role.arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.exfil_bucket.arn}/*"
      },
      {
        Sid    = "AllowDevUserRead"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.dev_user.arn
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.exfil_bucket.arn,
          "${aws_s3_bucket.exfil_bucket.arn}/*"
        ]
      },
      {
        Sid    = "AllowAttackerEC2Read"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.attacker_ec2_role.arn
        }
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

#############################################
# S3 Bucket with Flag (Goal)
#############################################

resource "aws_s3_bucket" "flag_bucket" {
  bucket        = "${local.scenario_name}-secret-flag"
  force_destroy = true

  tags = {
    Name = "${local.scenario_name}-secret-flag"
  }
}

resource "aws_s3_bucket_public_access_block" "flag_bucket_public_access" {
  bucket = aws_s3_bucket.flag_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "flag" {
  bucket  = aws_s3_bucket.flag_bucket.id
  key     = "flag.txt"
  content = <<-EOF
    ╔══════════════════════════════════════════════════════════════╗
    ║                     CONGRATULATIONS!                         ║
    ╠══════════════════════════════════════════════════════════════╣
    ║                                                              ║
    ║  You have successfully completed the iam_privesc_by_ec2     ║
    ║  scenario by exploiting the EC2 User Data modification      ║
    ║  privilege escalation technique!                             ║
    ║                                                              ║
    ║  FLAG: CG{us3r_d4t4_m0d1f1c4t10n_pr1v3sc_${random_string.suffix.result}}    ║
    ║                                                              ║
    ║  Attack Path:                                                ║
    ║  1. Started as dev_user with limited EC2 permissions        ║
    ║  2. Discovered target EC2 with privileged role              ║
    ║  3. Stopped the instance                                     ║
    ║  4. Modified user data to exfiltrate credentials            ║
    ║  5. Started the instance                                     ║
    ║  6. Retrieved admin credentials from S3                      ║
    ║  7. Used admin creds to access this flag!                   ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
  EOF

  tags = {
    Name = "scenario-flag"
  }
}
