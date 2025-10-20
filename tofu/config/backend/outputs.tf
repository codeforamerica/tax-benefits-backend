output "state_bucket" {
  description = "Name of the bucket used to store state files."
  value       = module.backend.bucket
}
