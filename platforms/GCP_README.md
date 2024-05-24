# Request Manager Agent: Google Cloud Configuration

- [Running the Agent](#running-the-agent)
- [Agent Platform Configuration](#agent-platform-configuration)
- [Example Configuration](#example-configuration)

## Running the Agent

### Sourcing the Image

The Docker image for the Request Manager agent is hosted in the DataGrail Artifact Registry repository, which you will be granted access. When retrieving the image, you should specify a version tag. For example:

- `us-west1-docker.pkg.dev/datagrail-202106/datagrail-rm-agent/datagrail-rm-agent:latest`
- `us-west1-docker.pkg.dev/datagrail-202106/datagrail-rm-agent/datagrail-rm-agent:v0.8.6`

**Note:** If you use `latest`, you will install the latest version available anytime your service restarts which could have breaking changes. We recommend specifying an explicit version.

### Deployments

We recommend using rolling deployments with a 100% minimum active percentage, and a maximum of 200%. This will avoid any downtime during releases, and also help alleviate any request congestion should many requests need to be serviced in parallel. We recommend using rolling (at a maximum of 50% per phase) or blue/green deployment strategies. It’s critical that your release configuration gives active inbound HTTPS requests a reasonable period (two minutes recommended) to complete before halting the container.

### Environment Variables

The Agent requires the following environment variables:

| Name                                  | Type   | Description |
|---------------------------------------|--------|-------------|
| `DATAGRAIL_AGENT_CONFIG`              | Object | Dictates target systems the Agent should connect to, what operations should be performed, and other metadata to instruct Agent behavior. For more information, see [Configuration](../CONFIGURATION.md) |
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | Object | Valid IAM service account JSON key with read access to Secret Manager and read/write access to your configured results bucket |

## Agent Platform Configuration

Set the following `platform` values in the `DATAGRAIL_AGENT_CONFIG` environment variable.

### Credentials Manager

To use Google Cloud Secrets Manager for storing agent and connection credentials, set the following `credentials_manager` values:

| Key                  | Value          | Description |
|----------------------|----------------|-------------|
| `provider`           | GCP            | Agent will use Google Cloud Secrets Manager |
| `options.project_id` | \<project id\> | Google Cloud Project ID |

**Example:**

```json
"credentials_manager": {
  "provider": "GCP",
  "options": {
    "project_id": "<project id>"
  }
}
```

### Storage Manager

To use Google Cloud Storage for storing the results of privacy requests, set the following `storage_manager` values:

**Note:** Use the same `bucket` name as configured on the DataGrail platform

| Key                  | Value           | Description |
|----------------------|-----------------|-------------|
| `provider`           | GCPCloudStore   | Agent will use Google Cloud Storage |
| `options.bucket`     | \<bucket name\> | Name of the bucket storing the results |
| `options.project_id` | \<project id\>  | Google Cloud Project ID |

**Example:**

```json
"storage_manager": {
  "provider": "GCPCloudStore",
  "options": {
    "bucket": "<bucket name>",
    "project_id": "<project id>"
  }
}
```

## Example Configuration

This example `DATAGRAIL_AGENT_CONFIG` environment variable uses GCP as the platform for managing credentials and storage:

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
