# Internal Systems Agent: Azure Configuration

Jump back to the [Main README](README.md)

## Agent Configuration

### Sourcing the Agent Image

The docker image for the internal systems agent is hosted in the DataGrail ECR repository, which you will be granted
access to. You should use an ARN with version specified for retrieving your image such as:

- `datagrailagent.azurecr.io/datagrail-agent:latest`
- `datagrailagent.azurecr.io/datagrail-agent:v0.7.2`

**Note:** If you use `latest`, you will install the latest version available anytime your service restarts which could
have breaking changes. We recommend specifying an explicit version.

You may optionally clone this image into your own docker repository (ECR or GCS Container Registry for example), or use
it directly from our repository in your install.

### Running the Agent

We recommend using rolling deployments with a 100% minimum active percentage, and a maximum of 200%. This will avoid any
downtime during releases, and also help alleviate any request congestion should many requests need to be serviced in
parallel. We recommend using rolling (at a maximum of 50% per phase) or blue/green deployment strategies. It’s critical
that your release configuration gives active inbound HTTPS requests a reasonable period (two minutes recommended) to
complete before halting the container.

The majority of the configuration of the agent itself happens through a single environment variable described in the
Agent Configuration section of this document. However, privileges granting read/write access to your configured
storage bucket are required.

For Azure we recommend specifying the following environment variables directly:

```
# AZURE Environment Variables:
AZURE_TENANT_ID="The Azure Active Directory tenant(directory) ID."
AZURE_CLIENT_ID="The client(application) ID of an App Registration in the tenant."
AZURE_CLIENT_SECRET="A client secret that was generated for the App Registration."

```

### Connection Configuration

The DataGrail agent’s primary configuration is sourced from an environment variable named `DATAGRAIL_AGENT_CONFIG`. This
configuration variable defines the connections available for the DataGrail agent and the credentials used for
authenticating with the DataGrail servers. The following is an example configuration variable. The fields and their
purpose are explained in detail below:

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
          "credentials_location": "<credentials location>"
      }
  ],
  "customer_domain": "<your datagrail customer domain>",
  "datagrail_agent_credentials_location": "<credentials location>",
  "datagrail_credentials_location": "<credentials location>",
  "platform": {
    "credentials_manager": {
      "provider": "<AzureKeyVault|AWSSSMParameterStore|AWSSecretsManager|JSONFile>",
      "options": {
        "optional": "some modules may have required fields, e.g. GCP should have project_id: <project id>, azure needs `secret_vault`",
      }
    },
    "storage_manager": {
      "provider": "<AWSS3|AzureBlob>",
      "options": {
        "bucket": "<bucket name, required>",
        "optional": "some modules may have additional required fields, e.g. GCP/Azure should have project_id: <project id>"
      }
    }
  }
  "redis_url": "connection string to remote redis instance (for multi-node deployments only)"
}'

```

**connections**

The connections array defines internal systems that the agent should connect to and their capabilities. It is also used
to map and classify system results back into DataGrail.

**name**

The friendly name of the target system. This string will be displayed in the request results inside DataGrail. The name
should be ASCII-only.

**uuid**

The uuid associated with the connection. This should be a v4 uuid and should be unique per-connection. You can use a
service like [UUID Generator](https://www.uuidgenerator.net/) to obtain these easily.

**capabilities**

Specifies the capabilities the connection should be used for. A connection should contain at least one capability. Valid
entries are:

`privacy/access` - the connection should be used to satisfy data access requests.

`privacy/delete` - the connection should be used to process deletion requests.

`privacy/identifiers` - the connection should be used to process identifier requests.

**mode**

Indicates the status of the connection. The mode “test” should be used for a connection that is not ready for use by
DataGrail in service of privacy requests. Otherwise the mode should be set to “live”.

**connector_type**

This field is used to configure the connector that DataGrail should use for the system connection. The adapter must be
in the set of supported system types. See the [connectors](../connectors) directory for available connectors.

**queries**

If the target system uses query strings for processing requests, they should be specified in the access and delete
arrays. The queries must accept a single parameter to which the user identifier will be passed.

**credentials_location**

A URL (e.g. to AzureKeyStore) which should point to the credentials associated with the connection. The format of the
credentials are specific to the target system, but are generally contained in a json-encoded dictionary stored in the
secret. For examples specific to your system, see the specific connector
documentation: [Snowflake](SNOWFLAKE.md), [SQL Server](SQL_SERVER.md), [SSH](SSH.md), etc.

**customer_domain**

Your DataGrail-registered customer domain.

**datagrail_agent_credentials_location**

The Azure Key Storage location containing OAuth credentials used by DataGrail to authenticate with the agent.

**datagrail_credentials_location**

The Azure Key Storage location for the credentials used to make callback requests to the DataGrail API. Your representative
will provide you with the value for this credential.

**platform**

The cloud provider used to deploy the `datagrail-agent`. `platform` requires two fields:

`credentials_manager` - settings for platform/credentials; see [credentials](../platforms/credentials)

`storage_manager` - information to access storage bucket used to upload results for privacy requests

**redis_url**

Optional field for multi-node deployments. `datagrail-agent` needs a persistent storage during its process lifetime
thus, if you have multiple nodes, they need to share a redis instance.
