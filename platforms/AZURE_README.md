# Request Manager Agent: Azure Configuration

- [Running the Agent](#running-the-agent)
- [Agent Platform Configuration](#agent-platform-configuration)
- [Example Configuration](#example-configuration)

## Running the Agent

### Sourcing the Image

The Docker image for the Request Manager Agent is hosted in the DataGrail Container Registry, which you will be granted access. When retrieving the image, you should specify a version tag. For example:

- `datagrailagent.azurecr.io/datagrail-rm-agent:latest`
- `datagrailagent.azurecr.io/datagrail-rm-agent:v0.8.6`

**Note:** If you use `latest`, you will install the latest version available anytime your service restarts which could have breaking changes. We recommend specifying an explicit version.

### Deployments

We recommend using rolling deployments with a 100% minimum active percentage, and a maximum of 200%. This will avoid any downtime during releases, and also help alleviate any request congestion should many requests need to be serviced in parallel. We recommend using rolling (at a maximum of 50% per phase) or blue/green deployment strategies. It’s critical that your release configuration gives active inbound HTTPS requests a reasonable period (two minutes recommended) to complete before halting the container.

### Environment Variables

The Agent requires the following environment variables:

| Name                     | Type   | Description |
|--------------------------|--------|-------------|
| `DATAGRAIL_AGENT_CONFIG` | Object | Dictates target systems the Agent should connect to, what operations should be performed, and other metadata to instruct Agent behavior. For more information, see [Configuration](../CONFIGURATION.md) |
| `AZURE_TENANT_ID`        | String | The Azure Active Directory tenant (directory) ID |
| `AZURE_CLIENT_ID`        | String | The client (application) ID of an App Registration in the tenant |
| `AZURE_CLIENT_SECRET`    | String | A client secret that was generated for the App Registration |

## Agent Platform Configuration

Set the following `platform` values in the `DATAGRAIL_AGENT_CONFIG` environment variable.

### Credentials Manager

To use Azure Key Vault for storing Agent and connection credentials, set the following `credentials_manager` values:

| Key                    | Value          | Description |
|------------------------|:--------------:|-------------|
| `provider`             | AzureKeyVault  | Agent will use Azure Key Vault |
| `options.secret_vault` | \<vault name\> | Name of the vault |

**Example:**

```json
"credentials_manager": {
  "provider": "AzureKeyVault",
  "options": {
    "secret_vault": "<vault name>"
  }
}
```

### Storage Manager

To use Azure Blob Storage for storing the results of privacy requests, set the following `storage_manager` values:

**Note:** Use the same `container` name as configured on the DataGrail platform

| Key                  | Value            | Description |
|----------------------|:----------------:|-------------|
| `provider`           | AzureBlob        | Agent will use Azure Blob Storage |
| `options.bucket`     | \<container name\>  | Name of the container storing the results |
| `options.project_id` | \<account name\> | Azure Blob Storage account name |

**Example:**

```json
"storage_manager": {
  "provider": "AzureBlob",
  "options": {
    "bucket": "<container name>",
    "project_id": "<account name>"
  }
}
```

## Example Configuration

This example `DATAGRAIL_AGENT_CONFIG` environment variable uses Azure as the platform for managing credentials and storage:

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
      "credentials_location": "<name of secret in Key Vault>"
    }
  ],
  "customer_domain": "<your datagrail customer domain>",
  "datagrail_agent_credentials_location": "<name of secret in Key Vault>",
  "datagrail_credentials_location": "<name of secret in Key Vault>",
  "platform": {
    "credentials_manager": {
      "provider": "AzureKeyVault",
      "options": {
        "secret_vault": "<vault name>"
      }
    },
    "storage_manager": {
      "provider": "AzureBlob",
      "options": {
        "bucket": "<container name>",
        "project_id": "<account name>"
      }
    }
  }
}
```
