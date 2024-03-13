############
# Required #
############
variable "region" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to place the agent into."
}

variable "public_subnet_ids" {
  type = set(string)
  validation {
    condition     = length(var.public_subnet_ids) == 2
    error_message = "Two public subnets must be specified."
  }
  description = "The IDs of the public subnets for the ALB to be placed into."
}

variable "private_subnet_id" {
  type        = string
  description = "The ID(s) of the private subnet(s) to put the datagrail-agent ECS task(s) into."
}

variable "agent_image_uri" {
  type        = string
  description = "The URI of the agent image"
}

variable "tls_certificate_arn" {
  type        = string
  description = "The ARN of the TLS certificate for the Application Load Balancer."
}

variable "hosted_zone_name" {
  type        = string
  description = "The name of the Route53 hosted zone where the public DataGrail agent subdomain will be created."
}

############
# Optional #
############
variable "project_name" {
  type        = string
  default     = "datagrail-rm-agent"
  description = "The name of the project. The value will be used in resource names as a prefix."
}

variable "create_vpc_endpoints" {
  type        = bool
  default     = true
  description = "Determines whether VPC Endpoints for ECR, S3, Cloudwatch, and optionally Secrets Manager, should be created"
}

variable "desired_task_count" {
  type        = number
  default     = 1
  description = "The desired number of tasks in the ECS service. If count is >1, you must use an external Redis Queue."
}

variable "cloudwatch_log_retention" {
  type        = number
  default     = 30
  description = "The retention period (in days) of the agent's CloudWatch log group."
}

variable "load_balancer_ingress_cidr" {
  type        = list(string)
  default     = []
  description = <<EOF
  Additional CIDR block(s) to add to the Application Load Balancer inbound rules.
  By default, only DataGrail's IP address can reach the ALB.
  EOF
}

variable "service_egress_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks to add to the agent service outbound rules."
}

variable "load_balancer_ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "cluster_id" {
  type        = string
  default     = ""
  description = <<EOF
  The ID of an existing cluster to place the datagrail-agent into.
  If omitted, a cluster named `datagrail-rm-agent-cluster` will be created.
  EOF
}

variable "agent_container_cpu" {
  type        = number
  default     = 1024
  description = "The CPU allotted for the agent container."
}

variable "agent_container_memory" {
  type        = number
  default     = 2048
  description = "The memory allotted for the agent container."
}

variable "agent_subdomain" {
  type        = string
  default     = "datagrail-agent"
  description = "The subdomain to create the agent at."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Default tags to add to resources that support them."
}