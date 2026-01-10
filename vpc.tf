#############################################
# VPC and Networking
# Private subnet WITHOUT VPC endpoints (no SSM)
#############################################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.scenario_name}-vpc"
  }
}

#############################################
# Internet Gateway (for public subnet)
#############################################

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.scenario_name}-igw"
  }
}

#############################################
# Public Subnet
#############################################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.scenario_name}-public-subnet"
    Type = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.scenario_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#############################################
# Private Subnet (NO NAT Gateway, NO VPC Endpoints)
# This means SSM will NOT work!
#############################################

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.scenario_name}-private-subnet"
    Type = "private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # No routes to internet - completely isolated!

  tags = {
    Name = "${local.scenario_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

#############################################
# Security Groups
#############################################

# Security group for the target EC2 (private)
resource "aws_security_group" "target_ec2" {
  name        = "${local.scenario_name}-target-sg"
  description = "Security group for target EC2 in private subnet"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound (but won't work without NAT/endpoints)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.scenario_name}-target-sg"
  }
}

# Security group for attacker EC2 (public) - used in exploitation
resource "aws_security_group" "attacker_ec2" {
  name        = "${local.scenario_name}-attacker-sg"
  description = "Security group for attacker EC2 in public subnet"
  vpc_id      = aws_vpc.main.id

  # SSH access from whitelisted CIDR
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.whitelisted_cidr]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.scenario_name}-attacker-sg"
  }
}
