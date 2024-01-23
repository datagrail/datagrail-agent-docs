# Introduction 
For many modern businesses, internal data systems are a large repository of sensitive personal information. DataGrail makes it simple to extend automating Data Subject Request (DSR) processing to these systems by deploying the DataGrail Request Manager Agent in your network to connect to your critical infrastructure.

Internal data must be handled with intention because it is:

**Highly sensitive:** The data most critical to operating your business.

**Delicate:** Altering certain data may have downstream effects (think of deleting a customer record and losing all revenue accounting for their associated orders).

**Fluid:** Modern organizations move fast, and their internal data footprint can change rapidly. In some organizations, self-serve tools might allow a wide range of individuals to make changes to internal data structures

## Our Approach
To solve this pain point, we’ve introduced the DataGrail Request Manager Agent for internal data systems. This agent can be installed in your infrastructure and handles the communication between the DataGrail application and your internal systems via a REST API interface.

This solution allows you to create any business logic you would like in your systems while maintaining a standardized interface with the DataGrail application. Our approach ensures the separation of concerns between your internal data operations and the privacy operations of fulfilling DSRs in DataGrail. 

## Deployment
The DataGrail Agent can be deployed in various cloud providers such as AWS, GCP, and Azure using container orchestration technologies like ECS and Kubernetes.

## Docker 
The DataGrail Agent will be provided as a Docker image which you will need to run in a container inside your infrastructure. The container will be configured through environment variables which will contain information about your internal systems, credentials, queries, and other metadata needed to run the agent.

## Networking
The DataGrail Agent running in your container must have network access to the internal systems you want to connect. Additionally, it must provide ingress from DataGrail to the API it serves. We recommend hosting the DataGrail Agent behind a customer-provided load balancer that handles SSL validation and termination.

## Flexibility
The DataGrail Agent makes connections to internal systems through a set of componentized integrations. DataGrail provides a standard set of integrations for use with common systems (databases, APIs, etc), however, the Agent is designed to be extended through the use of custom components to encompass any needs specific to your organization. These are developed as Python modules that the DataGrail Agent will automatically discover and connect to using the defined configurations.

## Request Processing
On receipt of a request for processing from DataGrail, the Agent will use the integration components to forward the requests on to the target system. The DataGrail Agent is designed to be able to handle any processing strategies in the target system through the integration components. Asynchronous and synchronous processing are both supported. 

Some custom development may be necessary depending on the target system in question. The DataGrail Agent is designed to handle the normalization of any data returned from the target system internally.

## Conclusion
The DataGrail Agent for Internal Systems Integration is designed to be simple, robust, and flexible, enabling you to connect DataGrail to any of your internal data in a secure manner while maintaining a clear separation of concerns between your internal data operations and DSR request fulfillment in DataGrail. The DataGrail team is available to assist in your deployment of this technology in your internal environment.

##Visit the [Configuration](/CONFIGURATION.md) document to get started. 