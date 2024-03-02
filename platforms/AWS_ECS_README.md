# Internal Systems Agent: AWS Configuration

Jump back to the [Main README](README.md)

## Agent Configuration

### Sourcing the Agent Image

The Docker image for the internal systems agent is hosted in the DataGrail ECR repository, which you will be granted access to. You should use an ARN with version specified for retrieving your image such as:

- `338780525468.dkr.ecr.us-west-2.amazonaws.com/datagrail-agent:latest`
- `338780525468.dkr.ecr.us-west-2.amazonaws.com/datagrail-agent:v1`

**Note:** If you use `latest`, you will install the latest version available anytime your service restarts which could have breaking changes. We recommend specifying an explicit version.

You may optionally clone this image into your own Docker repository (for example, AWS ECR or GCS Container Registry), or use it directly from our repository in your install.

### Running the Agent

We recommend using rolling deployments with a 100% minimum active percentage, and a maximum of 200%. This will avoid any downtime during releases, and also help alleviate any request congestion should many requests need to be serviced in parallel. We recommend using rolling (at a maximum of 50% per phase) or blue/green deployment strategies. It’s critical that your release configuration gives active inbound HTTPS requests a reasonable period (two minutes recommended) to complete before halting the container.

The majority of the configuration of the agent itself happens through a single environment variable described in the Agent Configuration section of this document. However, IAM privileges granting read/write access to your configured storage bucket are required.

In general we recommend doing this through IAM roles if you are operating in an AWS environment. However, you may also specify them as environment variables directly. The AWS library used requires the following variables be configured in that case:

```
AWS_ACCESS_KEY_ID = <IAM access key ID>
AWS_SECRET_ACCESS_KEY = <your IAM key secret>
AWS_REGION = <region your service will be operating in>
```

### Connection Configuration

The DataGrail agent’s primary configuration is sourced from an environment variable named `DATAGRAIL_AGENT_CONFIG`. This configuration variable defines the connections available for the DataGrail agent and the credentials used for authenticating with the DataGrail servers. The following is an example configuration variable. The fields and their purpose are explained in detail below:

```
DATAGRAIL_AGENT_CONFIG='{
  "connections": [
      {
          "name": "Accounts DB",
          "uuid": "<create UUID>",
          "capabilities": [ "privacy/access", "privacy/delete"],
          "mode": "live",
          "connector_type": "<connector type, e.g. Snowflake, SQLServer, SSH>",
          "queries": {
              "access": ["<access query>"],
              "delete": ["<deletion auery"]
          },
          "credentials_location": "<credentials arn>"
      }
  ],
  "customer_domain": "<your datagrail customer domain>",
  "datagrail_agent_credentials_location": "<credentials arn>",
  "datagrail_credentials_location": "<credentials arn>",
  "platform": {
    "credentials_manager": {
      "provider": "<AWSSSMParameterStore|AWSSecretsManager|JSONFile|AzureKeyVault|GCP>",
      "options": {
        "optional": "some modules may have required fields, e.g. GCP should have project_id: <project id>, azure needs `secret_vault`",
      }
    },
    "storage_manager": {
      "provider": "<AWSS3|AzureBlob|GCPCloudStore>",
      "options": {
        "bucket": "<bucket name, required>",
        "optional": "some modules may have additional required fields, e.g. GCP should have project_id: <project id>"
      }
    }
  }
  "redis_url": "connection string to remote redis instance (for multi-node deployments only)"
}'

# AWS configuration variables (required if your task execution role doesn't have all needed permissions)
AWS_ACCESS_KEY_ID=<aws access key ID>
AWS_SECRET_ACCESS_KEY=<aws secret access key>
AWS_REGION=<aws region>
```

**connections**

The connections array defines internal systems that the agent should connect to and their capabilities. It is also used to map and classify system results back into DataGrail.

**name**

The friendly name of the target system. This string will be displayed in the request results inside DataGrail. The name should be ASCII-only.

**uuid**

The uuid associated with the connection. This should be a v4 uuid and should be unique per-connection. You can use a service like [UUID Generator](https://www.uuidgenerator.net/) to obtain these easily.

**capabilities**

Specifies the capabilities the connection should be used for. A connection should contain at least one capability. Valid entries are:

`privacy/access` - the connection should be used to satisfy data access requests.

`privacy/delete` - the connection should be used to process deletion requests.

`privacy/identifiers` - the connection should be used to process identifier requests.

**mode**

Indicates the status of the connection. The mode “test” should be used for a connection that is not ready for use by DataGrail in service of privacy requests. Otherwise the mode should be set to “live”.

**connector_type**

This field is used to configure the connector that DataGrail should use for the system connection. The adapter must be in the set of supported system types. See the [connectors](../connectors) directory for available connectors.

**queries**

If the target system uses query strings for processing requests, they should be specified in the access and delete arrays. The queries must accept a single parameter to which the user identifier will be passed.

**credentials_location**

An AWS Secrets manager ARN which should contain the credentials associated with the connection. The format of the credentials are specific to the target system, but are generally contained in a json-encoded dictionary stored in the secret. For examples specific to your system, see the specific connector documentation: [Snowflake](../connectors/SNOWFLAKE.md), [SQL Server](../connectors/SQL_SERVER.md), [SSH](../connectors/SSH.md), etc.

**customer_domain**

Your DataGrail-registered customer domain.

**datagrail_agent_credentials_location**

The AWS Secrets manager ARN containing OAuth credentials used by DataGrail to authenticate with the agent.

**datagrail_credentials_location**

The AWS Secrets manager ARN for the credentials used to make callback requests to the DataGrail API. Your representative will provide you with the value for this credential.

**platform**

The cloud provider used to deploy the `datagrail-agent`. `platform` requires three fields:

`provider` - acronym for cloud provider e.g. `aws`, `gcp`, `azure`

`bucket` - storage bucket used to upload results for privacy requests

`project_id` - Required only for `GCP` and `Azure`. Unique string for specifying project

**redis_url**

Optional field for multi-node deployments. `datagrail-agent` needs a persistent storage during its process lifetime thus, if you have multiple nodes, they need to share a redis instance.

## ECS Quick-Setup Guide

The suggested deployment mechanism in AWS for the agent is via Amazon ECS. Deploying in an ECS service will result in most of the details of load balancing, ssl termination, and service uptime being managed in a simple and standard manner.

We recommend reading over the Amazon documentation on setting up an ECS service: Creating an Amazon ECS Service.

The following sections are the three main steps to creating an ECS agent service. Please note that depending on your AWS environment’s pre-existing configuration, you may need to take additional steps to configure your VPC, etc. Those are not covered in this document but we are happy to provide you with any assistance we can offer.

### 1. Create Task Definition

To configure the ECS service, you will need to define an ECS [“Task Definition”](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html), which contains all of the details on the agent container’s environment, configuration and system resources.

To create a task definition, navigate to the ECS task definition management page (make sure you select your desired AWS region). Select “Create New Task Definition”, and then select the “Fargate” template in the wizard that populates. The next page will be the main configuration screen for the task definition.

You’ll want to locate and click the “Configure via JSON” towards the bottom of the screen. This will open up a text box into which you can copy and paste the [task definition we’ve pre-populated](https://github.com/datagrail/datagrail-agent/tree/main/installation/examples/ecs_task_definition.json)
.

Your `DATAGRAIL_AGENT_CONFIG` environment variable will need to be modified with your specific connection + configuration information. To edit/override this, you should open the datagrail-agent container in the “container definitions” section of the page. This will open the container definition editor, and you can scroll down and locate the environment variables section to make your edits. For an easier time, you modify our [example configuration](https://github.com/datagrail/datagrail-agent/tree/main/installation/examples/agent_config.json). Click “Update” at the bottom right of the screen to persist your changes.

You will need to override/specify the “Task role” at the top of the main definition editor page. You should set this to an IAM role that has access to your AWS S3 results storage bucket and AWS Secrets Manager. Note that if you do not want to or cannot take this option, you can configure AWS CLI environment variables for the container giving the agent the ability to connect. The variables are defined in the “Running the Agent” section of this page.

You will also need to set the “Operating system family” to “Linux”.

Click “Create” at the bottom of the definition editor to create your new task definition!

### 2. Launch Load Balancer

The agent service will also require a load balancer to handle TLS Termination and traffic routing to the individual containers. ECS Service construction doesn’t handle this, so it will need to be configured manually.

To begin, navigate to the load balancer creation wizard (again, make sure you adjust the region if necessary). You’ll need to select the load balancer type “Application Load Balancer” in the first step.

On the second page of the wizard, you’ll want to select a unique name for the load balancer (we suggest datagrail-agent).

DataGrail requires that the load balancer be internet-facing, exist in a VPC subnet with ingress enabled, and use a security group that allows access to the load balancer through port 443 from our IP (specified in the “Network Communication Requirements” section of this document.

Additionally on this page you’ll want to add a listener for port 443. You’ll have the option to “create a target group” which will allow you to launch a target group creation wizard. Once in, you’ll need to select the target type “IP Addresses”, which ECS requires, and VPC + subnets, and security group, which can all match the settings for the main load balancer.

For the “health check path”, you’ll want to set the string value to be: /api/v1/hc.

On the next page of the target group wizard you can simply click “Create Target Group” - do not manually register any instances with this target group.

Back in the load balancer creation wizard, you can click “Create Load Balancer” to complete the setup.

### 3. Build ECS Service

The final step in setting up the ECS agent is configuring the service that will host the agent container tasks. Begin by navigating to the ECS console (again, select the appropriate region you wish to deploy in). Once here, you can either create a new, or select an existing ECS cluster to deploy the service in.

If you choose to create a cluster specifically for the agent, you can select the “Networking Only” option, since the agent will only run in AWS Fargate. For an existing cluster, it will need to either be “Networking Only”, or “EC2 Linux + Networking” - we do not support windows-based clusters.

Once you have the cluster created, from the cluster management page you should see a “Create” button in the “Services” tab. Click this to launch the service creation wizard.

In the wizard you’ll need to select “Fargate” as the launch type, and in the task definition drop down select the definition defined previously. Provide the service with a name (again we recommend datagrail-agent), and set the number of tasks to 1. You may then select “Next Step”.

On the next page you’ll need to configure your VPC + subnets, and assign a security group allowing ingress on ports 443 from DataGrail (you may use the same security group assigned to your load balancer). The VPC selected should match the VPC of your load balancer, but the assigned subnets may be private. “Auto-assign public IP” should be set to “disabled”.

Under “Load balancing”, you’ll want to select the option for “Application Load Balancer”. You should then be able to select your load balancer from the selection dropdown.

Click “Add to load balancer” in the “Container to load balance” section. The container + port dropdown should already be set to “datagrail-agent”. This should cause container load balancing configuration options to appear.

You’ll need to select `80:HTTP` as the “Production listener port” at the top of the configuration, and in the “Target group name” dropdown, select the load balancer target group created in the previous step.

Click “Next Step” to proceed to the final wizard screen. Nothing needs to be changed here, so you may click “Next Step” followed by “Create Service” to complete the setup process.

You should then see your service appear in the management page of your ECS cluster. Monitor the service “Running tasks” to ensure it reaches the desired count of 2. If tasks do not start within a few minutes, you can inspect the stopped tasks in the “Tasks” tab to look for any errors or failures.
