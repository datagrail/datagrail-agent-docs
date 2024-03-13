# Deploy the DataGrail Request Manager Agent with Terraform

## Prerequisites
This Terraform manages resources specific to the Agent. Shared resources the Agent depends upon must be configured separately and manually specified in advance.

### VPC
An existing VPC is required in this configuration. Endpoints to required AWS services can optionally be created by this Terraform within a single region. If the agent, S3 bucket, Secrets Manager entries, and CloudWatch group do not reside in the same region, the endpoints must be manually configured.

### Subnets
At least two public and one private subnet in the VPC above will need to exist and be created outside this Terraform configuration. An Application Load Balancer will be created in the public subnets to listen for incoming traffic which will forward traffic to the Agent in the private subnet. The private subnet must have a NAT Gateway in its route table so traffic can egress over the public internet back to DataGrail.

### NAT Gateway

The Agent, residing in a private subnet, needs access to the internet to call back to DataGrail. That private subnet will need to have a route to a NAT Gateway in a public subnet.

### Secrets
Secrets for the DataGrail Agent will need to be stored prior to running the configuration. The token used in the callback to DataGrail (`datagrail_credentials_location`), the credentials used for DataGrail application to authenticate with the DataGrail Agent (`datagrail_agent_credentials_location`), and the credentials for each connector (`credentials_location`) must be created in AWS Secrets Manager outside this Terraform.

### TLS Certificate
The Application Load Balancer will need to have an existing TLS certificate attached. This certificate should be for the domain that you plan on using to reach the agent.

### Route 53 Hosted Zone
The DataGrail Agent will have a subdomain in an existing Route 53 hosted zone. If the Agent will be reachable at `datagrail-agent.acme.com`, ensure you have a hosted zone for `acme.com`.

### Configuration File
The agent requires a configuration file. A sample of this configuration can be found in [config/datagrail-rm-agent-config.json.sample](config/datagrail-rm-agent-config.json.sample). Copy the contents into a file named `datagrail-agent-config.json` in the `config` directory and replace the `<SUBDOMAIN>` and `<BUCKET NAME>` placeholders.

## Managed Resources
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

The agent requires a `.tfvars` file. A sample of this file can be found in `variables.tfvars.sample`. Copy the contents into a file with a `.tfvars` extension and update the values as described in the following tables.

### Required

The agent requires the below variables to be declared in your `.tfvars` file. These variables will be used in Data Sources to reference existing resources.

| Name                  | Type     | Description                                                                                     |
|-----------------------|----------|-------------------------------------------------------------------------------------------------|
| `region`              | `string` | The region where the agent will be deployed.                                                    |
| `vpc_id`              | `string` | The ID of the VPC where the agent will be deployed.                                             |
| `public_subnet_ids`   | `string` | The IDs of the public subnets for the Application Load Balancer to be deployed.                 |
| `private_subnet_ids`  | `string` | The ID of the private subnet to deploy the datagrail-rm-agent ECS task(s).                      |
| `agent_image_uri`     | `string` | The URI of the agent image, with version tag, for the agent container.                          |
| `tls_certificate_arn` | `string` | The ARN of the TLS certificate for the Application Load Balancer.                               |
| `hosted_zone_name`    | `string` | The name of the Route53 hosted zone where the public DataGrail agent subdomain will be created. |
### Optional

You can optionally overwrite the default variable values below by declaring them in your `.tfvars` file. 

| Name                         | Type           | Default                               | Description                                                                                                                                                     |
|------------------------------|----------------|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
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
| `tags`                       | `map(string)`  | `{}`                                  | Default tags to add to resources that support them.                                                                                                             |