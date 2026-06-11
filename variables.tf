variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Environnement de déploiement (ex: dev, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "tp03"
}

variable "bastion_allowed_cidr" {
  description = "CIDR autorisé à se connecter en SSH au bastion"
  type        = string
}
variable "vpc_cidr" {
  description = "Plage IP (CIDR) du VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "public_key_path" {
  description = "Chemin vers la clé SSH publique"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
variable "azs" {
  description = "Liste des zones de disponibilite pour le deploiement"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}