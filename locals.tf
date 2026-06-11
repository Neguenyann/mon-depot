locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Configuration des sous-réseaux attendue par ton vpc.tf
  public_subnets = {
    "eu-west-3a" = "10.0.1.0/24"
    "eu-west-3b" = "10.0.2.0/24"
  }

  private_subnets = {
    "eu-west-3a" = "10.0.10.0/24"
    "eu-west-3b" = "10.0.11.0/24"
  }
}