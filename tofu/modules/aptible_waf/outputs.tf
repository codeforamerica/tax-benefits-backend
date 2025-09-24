output "origin_token_secret" {
  description = "Name of the secret used to store the origin token."
  value       = module.origin_secret.secret_name
}
