# 5. Output récapitulatif
locals {
  # ... locaux existants du TP02 (name_prefix, public_subnets, private_subnets) ...

  # Map AZ -> subnet_id prive, consommee par for_each sur aws_instance.web.
  web_subnets = { for k, s in aws_subnet.private : k => s.id }
}
output "bastion_public_ip" {
  description = "IP publique du Bastion"
  value       = aws_instance.bastion.public_ip
}

output "web_private_ips" {
  description = "IPs privees des serveurs Web Nginx"
  value       = { for az, instance in aws_instance.web : az => instance.private_ip }
}

output "web_instance_ids" {
  description = "IDs des instances des serveurs Web Nginx"
  value       = { for az, instance in aws_instance.web : az => instance.id }
}

output "ssh_bastion_command" {
  description = "Commande pour se connecter au bastion avec agent forwarding"
  value       = "ssh -i ${var.public_key_path} -A ec2-user@${aws_instance.bastion.public_ip}"
}