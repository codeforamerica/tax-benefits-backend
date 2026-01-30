variable "force_new_deployment" {
  type        = bool
  description = "Force new ECS service deployment, regardless of changed container status."
  default     = false
}