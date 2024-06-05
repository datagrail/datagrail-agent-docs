# Deploy the DataGrail Responsible Data Discovery Agent with Terraform

## Prerequisites
This Terraform manages resources specific to the Responsible Data Discovery Agent. Shared resources the Agent depends upon must be configured separately and manually specified in advance.

### VPC
An existing VPC is required in this configuration. Endpoints to required AWS services can optionally be created by this Terraform within a single region. If the Agent, Secrets Manager entries, and CloudWatch group do not reside in the same region, the endpoints must be manually configured.

### Subnets
One private subnet in the VPC will need to exist and be created outside this Terraform configuration. 

### NAT Gateway
The private subnet must have a NAT Gateway in its route table so traffic can egress over the public internet back to DataGrail.

### Secrets
Secrets for the DataGrail Agent will need to be stored prior to running the configuration. The token used in the callback to DataGrail (`datagrail_credentials_location`), and the credentials for each integration must be created in AWS Secrets Manager outside this Terraform.

### Configuration File
The Agent requires a configuration file to store metadata such as you DataGrail subdomain, credentials storage method and DataGrail credentials location. A sample of this configuration can be found in [rdd-agent-config.example.json](../rdd-agent-config.example.json).

## Managed Resources

### ECS Fargate Task(s)
An ECS Fargate Task(s) will be deployed in a Service in either an existing or new cluster. The service will live in an existing private subnet.

### Security Groups
Security Groups will be created for the Agent Service to restrict egress to VPC Endpoints for ECR, S3, Secrets Manager, CloudWatch, and DataGrail's IP.

### VPC Endpoints
VPC Endpoints can optionally be created to connect to various AWS services outside the VPC. 

### IAM Policy
A role with two policies will be created that are assumed by the Agent Service. The first is the AWS-managed AmazonECSTaskExecutionRolePolicy to grant access to ECR for pulling the Agent image and to CloudWatch to write to the Agent's Log Group. The second is a policy that grants the task Secrets Manager `GetSecretValue` permissions to retrieve the various configured secrets.

## Variables
The Terraform configuration requires a number of variables either declared in a `.tfvars` file or as parameters in the `apply` statement. If using a `.tfvars` file, copy the [`variables.sample.tfvars`](variables.example.tfvars) (`cp variables.sample.tfvars variables.tfvars` ) and update the values as described in the following tables.

### Required
| Name                 | Type     | Description                                                                |
|----------------------|----------|----------------------------------------------------------------------------|
| `region`             | `string` | The region where the agent will be deployed.                               |
| `vpc_id`             | `string` | The ID of the VPC where the agent will be deployed.                        |
| `private_subnet_id`  | `string` | The ID of the private subnet to deploy the datagrail-rm-agent ECS task(s). |
| `agent_image_uri`    | `string` | The URI of the Agent image, with version tag, for the agent container.     |

### Optional
| Name                       | Type           | Default                               | Description                                                                                                                                                     |
|----------------------------|----------------|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `project_name`             | `string`       | `datagrail-rm-agent`                     | The name of the project. The value will be prepended to resource names.                                                                                         |
| `create_vpc_endpoints`     | `bool`         | `true`                                | Determines whether VPC Endpoints for ECR, CloudWatch, and optionally Secrets Manager, should be created.                                                        |
| `desired_task_count`       | `number`       | `1`                                   | The desired number of tasks in the ECS service. If count is >1, you must use an external Redis Queue.                                                           |
| `cloudwatch_log_retention` | `number`       | `30`                                  | The retention period (in days) of the agent's CloudWatch log group.                                                                                             |
| `service_egress_cidr`      | `list(string)` | `[]`                                  | Additional CIDR block(s) to add to the Agent service outbound rules. By default, the only traffic allowed out of the service will be to DataGrail's IP address. |
| `cluster_arn`              | `string`       | `None`                                | The ID of an existing cluster to place the datagrail-rm-agent into. If omitted, a cluster named `datagrail-rdd-agent-cluster` will be created.                  |
| `agent_container_cpu`      | `number`       | `1024`                                | The CPU allotted for the Agent container.                                                                                                                       |
| `agent_container_memory`   | `number`       | `2048`                                | The memory allotted for the Agent container.                                                                                                                    |
| `tags`                     | `map(string)`  | `{}`                                  | Default tags to add to resources that support them.                                                                                                             |