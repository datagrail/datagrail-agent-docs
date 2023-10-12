# DataGrail Agent Configuration

To configure the `datagrail-agent` properly, you will need to:
1. Determine what connectors you want the agent to connect to
2. Create the secret(s) (for each connector), the `datagrail-agent` (OAuth client_id and client_secret), and the DataGrail API Key
3. Set the environment variables

## Setup

### Connectors

Take a look at [connectors](../connectors) directory for what connectors are available and choose what connectors you would like to set up. Each connector will have its own configuration represented in the `DATAGRAIL_AGENT_CONFIG` environment variable in the `connections` array field.

### Secrets

#### Connector Secret(s)

Each connector will need specific credentials to connect to the system, please refer to the respective connector's documentation in the [installation](../installation) directory to know what fields you will need to set.

#### Datagrail-agent Secret

When connecting to the agent, authorization will occur using OAuth which required a `client_id` and `client_secret`. Both of these fields will be stored in a secret and be read by the `datagrail-agent` to grant an `access_token` during the [client credentials](https://auth0.com/docs/get-started/authentication-and-authorization-flow/client-credentials-flow) flow.

In the agent configuration, the `datagrail_agent_credentials_location` field will be set with the  location (e.g. Amazon ARN) of the secret created. The contents of the secret will look like:

    Secret Type: "Other type of secret"
    Key/value pairs:
        client_id: <client id, e.g. datagrail>
        client_secret: <client secret (generated password)>
    Secret name: <name for the secret>
    Description: <description for the secret>

#### DataGrail API Key

For the `datagrail-agent` to talk back to the main DataGrail application, it will need an API key to authorize its requests. This API key will be stored in a secret under a `token` field.

In the agent configuration, the `datagrail_credentials_location` field will be set with the location (e.g. Amazon ARN) of the secret created. The contents of the secret will look like:

    Secret Type: "Other type of secret"
    Key/value pairs:
        token: <token to authenticate to datagrail, your DataGrail representative will send this>
    Secret name: <name for the secret>
    Description: <description for the secret>

### Environment Variables

You will need to set the following environment variables needed to run the `datagrail-agent`. Additionally, you will need to create uuids for your connectors for which you can use the [UUID Generator](https://www.uuidgenerator.net/).

**Example Environment Variable Configuration:**
```dotenv
# Primary Agent Config
DATAGRAIL_AGENT_CONFIG='{
  "connections": [
      {
          "name": "Accounts DB",
          "uuid": "<create UUID>",
          "capabilities": [ "privacy/access", "privacy/delete"],
          "mode": "live",
          "connector_type": "<connector type, e.g. Snowflake, SQLServer, SSH>",
          "queries": {
              "identifiers": {"<identifier name>": ["<identifier query>"]},
              "access": ["<access query>"],
              "delete": ["<deletion query>"]
          },
          "credentials_location": "<secret location>"
      }
  ],
  "customer_domain": "<your datagrail customer domain>",
  "datagrail_agent_credentials_location": "<secret location>",
  "datagrail_credentials_location": "<secret location>",
  "platform": {
    "credentials_manager": {
      "provider": "<AWSSSMParameterStore|AWSSecretsManager|JSONFile|GCP|AzureKeyVault>",
      "options": {
        "optional": "some modules may have required fields, e.g. GCP should have project_id: <project id>, azure needs `secret_vault`",
      }
    },
    "storage_manager": {
      "provider": "<GCPCloudStore|AWSS3|AzureBlob|BackblazeB2>",
      "options": {
        "bucket": "<bucket name, required>",
        "optional": "some modules may have additional required fields, e.g. GCP should have project_id: <project id>, Azure should have ["bucket", "project_id"]"
      }
    }
  }
  "redis_url": "connection string to remote redis instance (for multi-node deployments only)"
}'

# AWS configuration variables (if configured as AWS platform)
# If you have AWS credentials configured in your ~/.aws/credentials path, docker-compose will automatically pull them in so you don't have to configure it here
AWS_ACCESS_KEY_ID=<aws access key ID>
AWS_SECRET_ACCESS_KEY=<aws secret access key>
AWS_REGION=<aws region>
# Note: Backblaze uses AWS libraries, and as such, uses the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY variables for credentials.
# However, it requires the region to be set in the configuration, ignoring the AWS_REGION environment variable.
# Additionally, backblaze can use environment variables BACKBLAZE_ACCESS_KEY_ID and BACKBLAZE_SECRET_ACCESS_KEY to prevent conflict
# with existing AWS services like Secrets Manager.

# Google credentials JSON (if configured as GCP platform)
GOOGLE_APPLICATION_CREDENTIALS_JSON='<extracted google credentials file json>'

# AZURE Environment Variables:
AZURE_TENANT_ID="The Azure Active Directory tenant(directory) ID."
AZURE_CLIENT_ID="The client(application) ID of an App Registration in the tenant."
AZURE_CLIENT_SECRET="A client secret that was generated for the App Registration."

```

**NOTE:** `project_id` can be left blank if deploying in AWS, required for GCP

#### DATAGRAIL_AGENT_CONFIG

**connections**

The connections array defines internal systems that the agent should connect to and their capabilities. It is also used to map and classify system results back into DataGrail.

See [Connector Configuration](#connector-configuration) for documentation on specific connector configuration.

**customer_domain**

Your DataGrail-registered customer domain.

**datagrail_agent_credentials_location**

The AWS Secrets manager ARN containing OAuth credentials used by DataGrail to authenticate with the agent.

**datagrail_credentials_location**

The AWS Secrets manager ARN for the credentials used to make callback requests to the DataGrail API. Your representative will provide you with the value for this credential.

**platform**

The secrets/credentials and cloud storage platforms used to deploy the
`datagrail-agent`. `platform` requires two fields:

    "credentials_manager": {
      "provider": "<AWSSSMParameterStore|AWSSecretsManager|JSONFile|GCP>",
      "options": {
        "optional": "some modules may have required fields, e.g. GCP should have project_id: <project id>",
      }
    },
    "storage_manager": {
      "provider": "<GCPCloudStore|AWSS3|AzureBlob|BackblazeB2>",
      "options": {
        "bucket": "<bucket name, required>",
        "optional": "some modules may have additional required fields, e.g. GCP should have project_id: <project id>"
      }
    }


1. `credentials_manager`
   1. provider: name of class providing credentials access. Actual class name is e.g. CredentialsJSONFile, remove `Credentials` here, e.g. use `JSONFile`
   2. options: hash/dictinoary of options. Optional but some modules may have required fields, e.g. GCP should have "project_id": "<project id>"
2. `storage_manager`
    1. provider: name of class providing credentials access. Actual class name is e.g. CredentialsJSONFile, remove `Credentials` here, e.g. use `JSONFile`
    2. options:
       1. bucket: bucket name, required
       2. hash/dictinoary of options. Optional but some modules may have additional required fields, e.g. GCP should have "project_id": "<project id>"


**redis_url**

Optional field for multi-node deployments. `datagrail-agent` needs a persistent storage during its process lifetime thus, if you have multiple nodes, they need to share a redis instance.

##### Connector Configuration

Each connector will have its own configuration blob in the `connections` array field:

```
{
  "name": "Accounts DB",
  "uuid": "<create UUID>",
  "capabilities": [ "privacy/access", "privacy/delete"],
  "mode": "live",
  "connector_type": "<connector type, e.g. Snowflake, SQLServer, SSH>",
  "queries": {
      "identifiers": {"<identifier name>": ["<identifier query>"]},
      "access": ["<access query>"],
      "delete": ["<deletion auery"]
  },
  "credentials_location": "<secret location>"
}
```

**name**

The friendly name of the target system. This string will be displayed in the request results inside DataGrail. The name should be ASCII-only.

**uuid**

The uuid associated with the connection. This should be a v4 uuid and should be unique per-connection. You can use a service like [UUID Generator](https://www.uuidgenerator.net/) to obtain these easily.

**capabilities**

Specifies the capabilities the connection should be used for. A connection should contain at least one capability. Valid entries are:

`privacy/access` - the connection should be used to satisfy data access requests.

`privacy/delete` - the connection should be used to process deletion requests.

`privacy/identifiers` - the connection should be used to process identififer requests.

**mode**

Indicates the status of the connection. The mode “test” should be used for a connection that is not ready for use by DataGrail in service of privacy requests. Otherwise the mode should be set to “live”.

**connector_type**

This field is used to configure the connector that DataGrail should use for the system connection. The adapter must be in the set of supported system types. See the [connectors](../connectors) directory for available connectors.

**queries**

If the target system uses query strings for processing requests, they should be specified in the access and delete arrays. The queries must accept a single parameter to which the user identifier will be passed.

**credentials_location**

Local of the secret (e.g. AWS ARN) which should contain the credentials associated with the connection. The format of the credentials are specific to the target system, but are generally contained in a json-encoded dictionary stored in the secret. For examples specific to your system, see the specific connector documentation: [Snowflake](SNOWFLAKE.md), [SQL Server](SQL_SERVER.md), [SSH](SSH.md), etc.
