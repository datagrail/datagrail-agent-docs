# Deploy the DataGrail Internal Systems Agent with Terraform

## Prerequisites
This Terraform configuration handles the majority of the AWS resource configuration for you. There are, however, some 
resources that need to be set up outside of this configuration due to them likely already existing within your account 
or resources that you won't want control in this configuration because of the impact it may have on other parts of you 
infrastructure.

### VPC
An existing VPC is required in this configuration. The Terraform configuration does not support cross-region VPC interface
endpoints, so if you are operating your Postgres database out of RDS, for example, the VPC will need to exist in the
same region.

### Private Subnet
A private subnet in the aforementioned VPC will need to exist and be created outside this Terraform configuration. The
subnet must have a NAT Gateway in its route table so traffic can egress over the public internet back to DataGrail.

### Secrets
Secrets for both the DataGrail callback (`datagrail_credentials_location`), and for the connectors (`credentials_location`) 
must be created in AWS Secrets Manager outside this Terraform.

## RDD Scanner Architecture
### VPC
The RDD Scanner will be deployed in an existing VPC in an existing private subnet. The VPC you choose to deploy the 
scanner to should be the same as the data store the scanner will be connecting to lives. The private subnet should have 
a preconfigured NAT Gateway in order to allow traffic to egress the subnet to DataGrail

### ECS Fargate Task
The scanner will be deployed in a single container in an ECS Fargate Task in an existing cluster that will terminate 
once finished. You can optionally schedule this Task to run periodically through AWS EventBridge.

### Security Groups
The Task will have a security group attached with a single rule to restrict egress to the IP address of DataGrail's VPC.
The Terraform configuration optionally allows you to loosen egress by providing additional CIDR blocks.

### VPC Endpoints
The private subnet will have three VPC Interface Endpoints to connect to a few AWS services living outside of the VPC. 
The first is an ECR endpoint to facilitate pulling the scanner image from DataGrail’s ECR. The second is a Cloudwatch 
endpoint for the scanner to write the logs it emits to a configured Cloudwatch log group. The third is a Secrets Manager
endpoint to retrieve the credentials to connect to the configured data store(s). 

### IAM Policy
The ECS Task will assume a role with two policies attached. The first is the AWS-managed `AmazonECSTaskExecutionRolePolicy` 
that grants access to ECR for pulling the image and to Cloudwatch to write logs. The second is a policy that grants the 
task `GetSecretValue` permissions to get the various configured secrets.

## Variables

### Required
| Name                  | Type     | Description                                                                                     |
|-----------------------|----------|-------------------------------------------------------------------------------------------------|
| `region`              | `string` | The region where the agent will be deployed.                                                    |
| `vpc_id`              | `string` | The ID of the VPC where the agent will be deployed.                                             |
| `public_subnet_ids`   | `string` | The IDs of the public subnets for the Application Load Balancer to be deployed.                 |
| `agent_image_uri`     | `string` | The ID of the private subnet(s) to deploy the datagrail-agent ECS task(s).                      |
| `tls_certificate_arn` | `string` | The URI of the agent image, with version tag, for the agent container.                          |
| `hosted_zone_name`    | `string` | The name of the Route53 hosted zone where the public DataGrail agent subdomain will be created. |
### Optional
|                         Name | Type           | Default                               | Description                                                                                                                                                     |
|-----------------------------:|----------------|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `project_name`               | `string`       | `datagrail-agent`                     | The name of the project. The value will be prepended to resource names.                                                                                         |
| `create_vpc_endpoints`       | `bool`         | `true`                                | Determines whether VPC Endpoints for ECR, S3, Cloudwatch, and optionally Secrets Manager, should be created.                                                    |
| `desired_task_count`         | `number`       | `1`                                   | The desired number of tasks in the ECS service. If count is >1, you must use an external Redis Queue.                                                           |
| `cloudwatch_log_retention`   | `number`       | `30`                                  | The retention period (in days) of the agent's CloudWatch log group.                                                                                             |
| `load_balancer_ingress_cidr` | `list(string)` | `[]`                                  | Additional CIDR block(s) to add to the Application Load Balancer's inbound rules. By default, only DataGrail's IP address can reach the ALB.                    |
| `service_egress_cidr`        | `list(string)` | `[]`                                  | Additional CIDR block(s) to add to the agent service outbound rules. By default, the only traffic allowed out of the service will be to DataGrail's IP address. |
| `load_balancer_ssl_policy`   | `string`       | `ELBSecurityPolicy-TLS13-1-2-2021-06` | The name of the SSL policy for the load balancer's listener.                                                                                                    |
| `cluster_id`                 | `string`       | `None`                                | The ID of an existing cluster to place the datagrail-agent into. If omitted, a cluster named `datagrail-agent-cluster` will be created.                         |
| `agent_container_cpu`        | `number`       | `1024`                                | The CPU allotted for the agent container.                                                                                                                       |
| `agent_container_memory`     | `number`       | `2048`                                | The memory allotted for the agent container.                                                                                                                    |
| `agent_subdomain`            | `string`       | `datagrail-agent`                     | The subdomain to create the agent at.                                                                                                                           |