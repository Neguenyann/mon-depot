# ==============================================================================
# DATA SOURCES (AMI)
# ==============================================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# ==============================================================================
# RESSOURCES SECURITE & ACCES
# ==============================================================================

resource "aws_key_pair" "formation" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = file(pathexpand(var.public_key_path))

  tags = {
    Name  = "${var.project_name}-${var.environment}-key"
    Owner = "etudiant23"
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Security group pour le bastion SSH"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name  = "${var.project_name}-${var.environment}-bastion-sg"
    Owner = "etudiant23"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH depuis l exterieur"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.bastion_allowed_cidr

  tags = {
    Name  = "${var.project_name}-${var.environment}-bastion-ssh-rule"
    Owner = "etudiant23"
  }
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name  = "${var.project_name}-${var.environment}-bastion-egress-rule"
    Owner = "etudiant23"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group pour les serveurs web prives"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name  = "${var.project_name}-${var.environment}-web-sg"
    Owner = "etudiant23"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id            = aws_security_group.web.id
  description                  = "SSH depuis le Bastion"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id

  tags = {
    Name  = "${var.project_name}-${var.environment}-web-ssh-rule"
    Owner = "etudiant23"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP depuis le VPC"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr

  tags = {
    Name  = "${var.project_name}-${var.environment}-web-http-rule"
    Owner = "etudiant23"
  }
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name  = "${var.project_name}-${var.environment}-web-egress-rule"
    Owner = "etudiant23"
  }
}

# ==============================================================================
# INSTANCES COMPUTE (EC2)
# ==============================================================================

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public["eu-west-3a"].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = aws_key_pair.formation.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  volume_tags = {
    Name  = "${var.project_name}-${var.environment}-bastion-ebs"
    Owner = "etudiant23"
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-bastion"
    Project = var.project_name
    Owner   = "etudiant23"
  }
}

resource "aws_instance" "web" {
  for_each = toset(var.azs)

  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[each.key].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = aws_key_pair.formation.key_name
  user_data                   = templatefile("${path.module}/templates/nginx.sh.tftpl", { az = each.key })
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  volume_tags = {
    Name  = "${var.project_name}-${var.environment}-web-${each.key}-ebs"
    Owner = "etudiant23"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-web-${each.key}"
    Project = var.project_name
    Owner   = "etudiant23"
  }
}