# DataGrail Request Manager Agent #
##  Motivation ##
For many modern businesses, internal data systems are a large repository of sensitive personal information. DataGrail makes it simple to extend automating Data Subject Request (DSR) processing to these systems by deploying the DataGrail Request Manager Agent in your network to connect to your critical infrastructure.

Internal data must be handled with intention because it is:

* **Highly sensitive:** The data most critical to operating your business.

* **Delicate:** Altering certain data may have downstream effects (think of deleting a customer record and losing all revenue accounting for their associated orders).

* **Fluid:** Modern organizations move fast, and their internal data footprint can change rapidly. In some organizations, self-serve tools might allow a wide range of individuals to make changes to internal data structures

## Our Approach
To solve this pain point, DataGrail has created the Request Manager Agent for internal data systems. This Agent can be installed in your infrastructure to handle the communication between the DataGrail application and your internal systems via a REST API interface.

This solution allows you to create any business logic you would like in your systems while maintaining a standardized interface with the DataGrail application. Our approach ensures the separation of concerns between your internal data operations and the privacy operations of fulfilling DSRs in DataGrail. 

## Easy to Deploy

The DataGrail Agent will be provided as a Docker image to run in a container virtually anywhere. The Agent container is configured through environment variables which contain metadata to dictate how to interact with your systems.

Host the Agent alongside your cloud-based systems on AWS, GCP, and Azure, using container orchestration technologies like ECS and Kubernetes.

Leverage our [Terraform](/terraform) configurations for quick and predictable deployments.

## Secure by Design

Deploying the Agent in your network gives you complete control of the connection to your internal systems.

Network ingress to the Agent is secured with OAuth, TLS, and well-defined traffic rules, while internal system connectivity from the Agent is defined by you. Internal system access provided to the Agent uses the principle of least privilege to only access what’s needed.


## Flexible Connectors

Communicate with internal systems (databases, data warehouses, APIs, etc.) using one of the many pre-built [connectors](/connectors), or extend our base components to encompass any needs specific to your organization.

Internal systems change over time and it's easy to update the Agent to encompass new systems to include in DSR processing automation. 


## Quickstart
* **[Learn how to configure the Agent](/CONFIGURATION.md)**
* **[Use Terraform to deploy the Agent in AWS ECS](/terraform/request_managaer/aws/ecs)**
* **[Use Terraform to deploy the Agent in GCP Cloud Run](/terraform/request_manager/gcp/cloud_run)**
