# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name     = "${local.name_prefix}-vpc"
    Owner = "etudiant23"
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name     = "${local.name_prefix}-igw"
    Owner = "etudiant23"
  }
}

# -----------------------------------------------------------------------------
# Subnets publics (1 par AZ)
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name     = "${local.name_prefix}-public-${each.key}"
    Tier     = "public"
    Owner = "etudiant23"
  }
}

# -----------------------------------------------------------------------------
# Subnets prives (1 par AZ)
# -----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name     = "${local.name_prefix}-private-${each.key}"
    Tier     = "private"
    Owner = "etudiant23"
  }
}

# -----------------------------------------------------------------------------
# Elastic IP pour le NAT Gateway
# -----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name     = "${local.name_prefix}-nat-eip"
    Owner = "etudiant23"
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# NAT Gateway (single, dans la 1ere AZ)
# -----------------------------------------------------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["eu-west-3a"].id

  tags = {
    Name     = "${local.name_prefix}-nat"
    Owner = "etudiant23"
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Route table publique : 0.0.0.0/0 -> IGW
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name     = "${local.name_prefix}-public-rt"
    Owner = "etudiant23"
  }
}

# -----------------------------------------------------------------------------
# Route table privee : 0.0.0.0/0 -> NAT
# -----------------------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name     = "${local.name_prefix}-private-rt"
    Owner = "etudiant23"
  }
}

# -----------------------------------------------------------------------------
# Associations route table - subnet
# -----------------------------------------------------------------------------
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}