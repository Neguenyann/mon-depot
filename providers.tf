# providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Ou la version que vous avez choisie
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "formation-terraform"
      Module      = "tp02-vpc"
      ManagedBy   = "Terraform"
      Etudiant    = "etudiant23"
    }
  }
}

variable "instance_type" {
  description = "Type d'instance EC2 pour le bastion et les serveurs web"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  description = "Chemin vers la clé SSH publique locale"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
