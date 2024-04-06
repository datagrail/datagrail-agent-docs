# Google Cloud Platform (GCP)

- [Running the Agent](#running-the-agent)
  - [Sourcing the Agent Image](#sourcing-the-agent-image)
  - [Deployment and Scaling](#deployment-and-scaling)
  - [Environment Variables](#environment-variables)
- [Agent Configuration Variable](#agent-configuration-variable)
  - [Credentials Manager](#credentials-manager)
  - [Storage Manager](#storage-manager)
  - [Example Agent Configuration](#example-agent-configuration)

## Running the Agent

### Sourcing the Agent Image

The Docker image for the Request Manager agent is hosted in a DataGrail Artifact Registry repository, which you will be granted access. When retrieving the image, you should specify a version tag. For example:

- `us-west1-docker.pkg.dev/datagrail-202106/datagrail-rm-agent/datagrail-rm-agent:latest`
- `us-west1-docker.pkg.dev/datagrail-202106/datagrail-rm-agent/datagrail-rm-agent:v0.8.6`

**Note:** If you use `latest`, you will install the latest version available anytime your service restarts which could have breaking changes. We recommend specifying an explicit version.

You may optionally clone this image into your own Docker repository (for example, AWS ECR or GCP Artifact Registry), or use it directly from our repository in your install.

### Deployment and Scaling

We recommend using rolling deployments with a 100% minimum active percentage, and a maximum of 200%. This will avoid any downtime during releases, and also help alleviate any request congestion should many requests need to be serviced in parallel. We recommend using rolling (at a maximum of 50% per phase) or blue/green deployment strategies. It’s critical that your release configuration gives active inbound HTTPS requests a reasonable period (two minutes recommended) to complete before halting the container.

### Environment Variables

The agent requires the following environment variables:

| Name                                  | Type   | Description |
|---------------------------------------|--------|-------------|
| `DATAGRAIL_AGENT_CONFIG`              | Object | Dictates target systems the Agent should connect to, what operations should be performed, and other metadata to instruct Agent behavior |
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | Object | Valid IAM service account JSON key with read access to Secret Manager and read/write access to your configured results bucket |

## Agent Configuration Variable

When defining the [agent configuration variable](../CONFIGURATION.md), set the following `platform` values:

| Platform              | Provider          | Service        | Purpose |
|-----------------------|-------------------|-----------------|---------|
| `credentials_manager` | **GCP**           | Secrets Manager | Stores the credentials for the agent and connections |
| `storage_manager`     | **GCPCloudStore** | Cloud Storage   | Uploading the results of privacy requests |

### Credentials Manager

Set the following `credentials_manager` object values to use Google Cloud Secrets Manager:

| Key                  | Value          | Description |
|----------------------|----------------|-------------|
| `provider`           | GCP            | Agent will use Secrets Manager |
| `options.project_id` | \<project id\> | Google Cloud Project ID of Secrets Manager |

#### Example - Credentials Manager

```json
"credentials_manager": {
  "provider": "GCP",
  "options": {
    "project_id": "<project id>"
  }
}
```

### Storage Manager

Set the following `storage_manager` object values to use Google Cloud Storage for storing the results of privacy results:

**Note:** Use the same `bucket` name as configured on the DataGrail platform

| Key                  | Value           | Description |
|----------------------|-----------------|-------------|
| `provider`           | GCPCloudStore   | Agent will use Cloud Storage |
| `options.bucket`     | \<bucket name\> | Bucket name that stores the results of privacy results |
| `options.project_id` | \<project id\>  | Google Cloud Project ID of the storage bucket |

#### Example - Storage Manager

```json
"storage_manager": {
  "provider": "GCPCloudStore",
  "options": {
    "bucket": "<bucket name>",
    "project_id": "<project id>"
  }
}
```

### Example Agent Configuration

The following is an example of the `DATAGRAIL_AGENT_CONFIG` environment variable using GCP as the platform for managing both storage and credentials:

```json
{
  "connections": [
    {
      "name": "Your Connection",
      "uuid": "<create UUID>",
      "capabilities": ["privacy/access","privacy/delete"],
      "mode": "live",
      "connector_type": "<connector type, e.g. Snowflake, SQLServer, SSH>",
      "queries": {
        "access": ["<access query>"],
        "delete": ["<deletion query"]
      },
      "credentials_location": "<name of secret in Secrets Manager>"
    }
  ],
  "customer_domain": "<your datagrail customer domain>",
  "datagrail_agent_credentials_location": "<name of secret in Secrets Manager>",
  "datagrail_credentials_location": "<name of secret in Secrets Manager>",
  "platform": {
    "credentials_manager": {
      "provider": "GCP",
      "options": {
        "project_id": "<project id>"
      }
    },
    "storage_manager": {
      "provider": "GCPCloudStore",
      "options": {
        "bucket": "<bucket name>",
        "project_id": "<project id>"
      }
    }
  }
}
```
