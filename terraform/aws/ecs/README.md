# Deploy the DataGrail Internal Systems Agent with Terraform

## Prerequisites
This Terraform configuration handles the majority of the AWS resource configuration for you. There are, however, some resources that need to be set up outside of this configuration due to them likely already existing in your account or resources that you won't want control in this configuration because of the impact it may have on other parts of your infrastructure.

### VPC
An existing VPC is required in this configuration. The Terraform configuration does not support cross-region VPC interface endpoints, so the agent will need to be deployed in the same region as your S3 bucket, Secrets Manager, and CloudWatch group.

### Subnets
Two public and one private subnet in the VPC above will need to exist and be created outside this Terraform configuration. An Application Load Balancer will be created in the public subnet to listen for incoming traffic which will forward traffic to the agent in the private subnet. The private subnet must have a NAT Gateway in its route table so traffic can egress over the public internet back to DataGrail.

### Secrets
Secrets for the DataGrail callback (`datagrail_credentials_location`), the DataGrail Agent credentials (`datagrail_agent_credentials_location`), and the list of connectors (`credentials_location`) must be created in AWS Secrets Manager outside this Terraform.

### TLS Certificate
The Application Load Balancer will need to have an existing TLS certificate attached. This certificate should be for the domain that you plan on using to reach the agent.

### Configuration File
The agent requires a configuration file to dictate various behavior. Upon startup, the agent performs schema validation of the file to ensure that all requirements are met, and will fail if they aren't. When first deploying the agent without connections to your internal systems, a minimum viable configuration is required to get it running. A sample of this configuration can be found in [config/datagrail-agent-config.json.sample](config/datagrail-agent-config.json.sample). Copy the contents into a file named `datagrail-agent-config.json` in the `config` directory and replace the `<SUBDOMAIN>` and `<BUCKET NAME>` placeholders.

## Agent Architecture
### VPC and Subnets
Two public and one private subnet will be used in a VPC of your choice. An Application Load Balancer will live in the two public subnets and forward traffic to the agent in the private subnet. The VPC you choose to deploy the agent to should be the same as the one where your preconfigured S3 bucket, Secrets Manager, and CloudWatch reside. Traffic will egress the private subnet back to DataGrail via NAT gateway.

### Application Load Balancer
An Application Load Balancer will be created to listen for incoming traffic from DataGrail’s VPC, handle TLS termination, and forward to the agent task(s).

### ECS Fargate Task(s)
The agent will be deployed in a single container in an ECS Fargate Task in either an existing or new cluster. The service will live in an existing private subnet.

### Security Groups
The Application Load Balancer will have an attached security group that restricts ingress to DataGrail’s VPC IP by default. The agent task has a security group with rules to restrict ingress to the Application Load Balancer and egress to DataGrail’s VPC IP. The Terraform configuration optionally allows you to loosen inbound/outbound rules by providing additional CIDR blocks to both the load balancer and task.

### VPC Endpoints
The private subnet will have four VPC Interface Endpoints to connect to various AWS services living outside the VPC. The first is an ECR endpoint to facilitate pulling the scanner image from DataGrail’s ECR. The second is a Cloudwatch endpoint for the agent to write logs to a configured Cloudwatch log group. The third is a Secrets Manager endpoint to retrieve the credentials to connect to the configured data store(s). The fourth is an S3 endpoint to write the results of requests to a preconfigured S3 bucket.

### IAM Policy
The ECS Task will assume a role with two policies attached. The first is the AWS-managed `AmazonECSTaskExecutionRolePolicy` that grants access to ECR for pulling the image and to Cloudwatch to write logs. The second is a policy that grants the task S3 `PutObject` permission to the defined S3 bucket, and Secrets Manager `GetSecretValue` permissions to retrieve the various configured secrets.


## Variables

### Required

The agent requires the below variables to be declared in your `.tfvars` file. These variables will be used in Data Sources to reference existing resources.

| Name                  | Type     | Description                                                                                     |
|-----------------------|----------|-------------------------------------------------------------------------------------------------|
| `region`              | `string` | The region where the agent will be deployed.                                                    |
| `vpc_id`              | `string` | The ID of the VPC where the agent will be deployed.                                             |
| `public_subnet_ids`   | `string` | The IDs of the public subnets for the Application Load Balancer to be deployed.                 |
| `agent_image_uri`     | `string` | The ID of the private subnet(s) to deploy the datagrail-agent ECS task(s).                      |
| `tls_certificate_arn` | `string` | The URI of the agent image, with version tag, for the agent container.                          |
| `hosted_zone_name`    | `string` | The name of the Route53 hosted zone where the public DataGrail agent subdomain will be created. |
### Optional

You can optionally overwrite the default variable values below by declaring them in your `.tfvars` file. 

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