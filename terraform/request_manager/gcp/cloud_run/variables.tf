variable "project_id" {
  type = string
}

variable "name" {
  description = "Name for the forwarding rule and prefix for supping resources."
  type        = string
  default     = "datagrail-rm-agent"
}

variable "region" {
  description = "Location for load balancer and Cloud Run resources"
  default     = "us-central1"
}

variable "ssl" {
  description = "Run load balancer on HTTPS and provision managed certificate with provided `domain`."
  type        = bool
  default     = true
}

variable "domain" {
  description = "Domain name to run the load balancer on. Used if `ssl` is `true`."
  type        = string
}

variable "agent_image" {
  description = "The datagrail-rm-agent image in Artifact Registry to use."
  type        = string
}

