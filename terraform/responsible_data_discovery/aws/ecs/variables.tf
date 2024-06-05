############
# Required #
############
variable "region" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to place the Agent into."
}

variable "private_subnet_id" {
  type        = string
  description = "The ID(s) of the private subnet(s) to put the datagrail-rdd-agent ECS task(s) into."
}

variable "agent_image_uri" {
  type        = string
  description = "The URI of the Agent image"
}

############
# Optional #
############
variable "project_name" {
  type        = string
  default     = "datagrail-rdd-agent"
  description = "The name of the project. The value will be used in resource names as a prefix."
}

variable "create_vpc_endpoints" {
  type        = bool
  default     = true
  description = "Determines whether VPC Endpoints for ECR, Cloudwatch, and optionally Secrets Manager, should be created"
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

variable "service_egress_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks to add to the agent service outbound rules."
}

variable "cluster_arn" {
  type        = string
  default     = ""
  description = <<EOF
  The ARN of an existing cluster to place the datagrail-agent into.
  If omitted, a cluster named `datagrail-rdd-agent-cluster` will be created.
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

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Default tags to add to resources that support them."
}