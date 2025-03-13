############
# Required #
############

variable "vpc_id" {
  description = "The ID of the VPC to place the agent into."
  type        = string
}

variable "private_subnet_ids" {
  description = "The ID(s) of the private subnet(s) to put the datagrail-rdd-agent ECS task(s) into."
  type        = list(string)
}

variable "datagrail_subdomain" {
  description = "The domain of your DataGrail instance, e.g. acme.datagrail.io."
  type        = string
}

variable "credentials_manager" {
  description = "The credentials manager used to store secrets, e.g. DataGrail API token and data store credentials."
  type        = string
  validation {
    condition     = contains(["AWSSecretsManager", "AWSParameterStore", "JSONFile"], var.credentials_manager)
    error_message = "Credentials manager must be one of: AWSSecretsManager, AWSParameterStore, JSONFile"
  }
}

variable "agent_image_uri" {
  description = "The URI, along with version tag, of the RDD agent image."
  type        = string
}

variable "datagrail_api_key" {
  description = "API token used to authenticate requests to DataGrail."
  type        = string
}

variable "integration_credentials_arns" {
  description = "The ARNs of the integration credentials the agent should have permission to get."
  type = list(string)
  default = []
}

############
# Optional #
############

variable "project_name" {
  description = "The name of the project. The value will be used in resource names as a prefix."
  type        = string
  default     = "datagrail-rdd-agent"
}

variable "desired_task_count" {
  description = "The desired number of tasks in the ECS service. If count is >1, you must use an external Redis Queue."
  type        = number
  default     = 1
}

variable "cloudwatch_log_retention" {
  description = "The retention period (in days) of the agent's CloudWatch log group."
  type        = number
  default     = 30
}

variable "cluster_arn" {
  description = "The ARN of an existing cluster to place the agent into."
  type        = string
  default     = ""
}

variable "agent_container_cpu" {
  description = "The CPU allotted for the agent container."
  type        = number
  default     = 4096
}

variable "agent_container_memory" {
  description = "The memory allotted for the agent container."
  type        = number
  default     = 8192
}

variable "tags" {
  description = "Default tags to add to resources that support them."
  type        = map(string)
  default     = {}
}