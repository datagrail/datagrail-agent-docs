# DataGrail Agent Configuration

The DataGrail Agent configuration variables dictate the target systems the Agent should connect to, what operations should be performed, as well as other metadata to instruct Agent behavior. 

To configure the DataGrail Agent properly, you will need to:
1. Determine the system(s) you want the Agent to connect to, their associated connector(s) and the applicable queries.
2. Create and store secrets for:
   1. Each connector.
   2. The OAuth Client Credentials for the Agent to authorize operations by the DataGrail application.
   3. The callback token to authenticate the Agent's callbacks to the DataGrail platform.
3. Set the environment variable(s).

## Configuration

### Connectors

Take a look at the [connectors](/connectors) directory for what connectors are available and choose the ones you would like to set up. Each connector will have its own configuration represented in the `DATAGRAIL_AGENT_CONFIG` environment variable in the `connections` array field. Example configurations for each connector are available in their respective document.

### Secrets
The Agent will use a supported secrets manager to store all secrets.

##### Connector Secret(s)
Each connector will need credentials to establish a connection to the system. You can refer to the respective connector's documentation in the [connectors](connectors) directory to know what credential parameters each connector requires.

##### OAuth Client Credentials
DataGrail will be authorized to access the Agent's resources using the [OAuth Client Credentials](https://www.oauth.com/oauth2-servers/access-tokens/client-credentials/) grant type. The `client_id` and `client_secret` are arbitrary values that you will create to be read by the Agent to grant an access token during the [Client Credentials flow](https://auth0.com/docs/get-started/authentication-and-authorization-flow/client-credentials-flow).

In your secrets manager, store a `client_id` and `client_secret`. The raw contents of the secret should be in JSON format with the following key/value pairs:

```json
{
"client_id": "<client ID, e.g. 'datagrail'>",
"client_secret": "<client secret (generated password)>"
}
```

##### DataGrail Callback Token

For the Agent to make calls back to the DataGrail application, it will need an API token to authorize its requests. Your DataGrail representative will provide this key to you. 

In your secrets manager, store your DataGrail-provided callback token. The raw contents of the secret should be in a JSON format with the following format:

```json
{
"token": "<your provided DataGrail token>"
}
```
### Environment Variables

The `DATAGRAIL_AGENT_CONFIG`

```dotenv
DATAGRAIL_AGENT_CONFIG='{
  "connections": [
      {
          "name": "<friendly name of the integration i.e. User DB (shown in the DataGrail application)>",
          "uuid": "<create UUID>",
          "capabilities": [<one or more of: "privacy/access|privacy/delete|privacy/identifiers”>],
          "mode": "<live|test>",
          "connector_type": "<connector type, e.g. Snowflake, SQLServer, SSH>",
          "queries": {
              "identifiers": {"<identifier name>": ["<identifier query>"]},
              "access": ["<access queries>"],
              "delete": ["<deletion queries>"]
          },
          "credentials_location": "<connector secret location>"
      }
  ],
  "customer_domain": "<your datagrail customer domain>",
  "datagrail_agent_credentials_location": "<Agent client ID/secret location>",
  "datagrail_credentials_location": "<DataGrail API key location>",
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

#
```


#### DataGrail Agent Configuration Parameter Definitions

**`connections`**

The connections array defines target systems that the agent should connect to and their capabilities. It is also used to map and classify system results back into DataGrail.

See the [Connector Configuration](/connectors) documentation for specifics on connector configurations.

**`customer_domain`**

Your DataGrail-registered customer domain.

**`datagrail_agent_credentials_location`**

The location (e.g. AWS Secrets Manager ARN) of the [DataGrail Agent Client ID/Client Secret](#DataGrail Agent Client ID/Client Secret) used by DataGrail to authenticate with the Agent.

**`datagrail_credentials_location`**

The location of the [DataGrail Callback Token](#DataGrail Callback Token) used to make callback requests to the DataGrail API. Your representative will provide you with the value of this credential.

**`platform`**

The secrets/credentials and cloud storage platforms used to deploy the
Agent. `platform` requires two blocks:

    "credentials_manager": {
      "provider": "<AWSSSMParameterStore|AWSSecretsManager|JSONFile|GCP>",
      "options": {
        "<option name>": "some modules may have required fields, e.g. GCP should have project_id: <project id>",
      }
    },
    "storage_manager": {
      "provider": "<GCPCloudStore|AWSS3|AzureBlob|BackblazeB2>",
      "options": {
        "bucket": "<bucket name, required>",
        "<option name>": "some modules may have additional required fields, e.g. GCP should have project_id: <project id>"
      }
    }


1. `credentials_manager`
   1. `provider`: name of class providing credentials access. The actual class name is e.g. CredentialsJSONFile, remove `Credentials` here, e.g. use `JSONFile`
   2. `options`: hash/dictionary of options. Optional but some modules may have required fields, e.g. GCP should have "project_id": "<project id>"
2. `storage_manager`
    1. `provider`: name of class providing credentials access. The actual class name is e.g. CredentialsJSONFile, remove `Credentials` here, e.g. use `JSONFile`
    2. `options`:
       1. `bucket`: bucket name, required
       2. hash/dictionary of options. Optional but some modules may have additional required fields, e.g. GCP should have "project_id": "<project id>"


**`redis_url`**

Optional field for multi-node deployments. The Agent needs persistent storage during its process lifetime thus, if you have multiple nodes, they need to share a Redis instance.

#### Amazon Web Services

| Name                     | Value                                                                                            |
|--------------------------|--------------------------------------------------------------------------------------------------|
| `AWS_ACCESS_KEY_ID`      | AWS access key associated with an IAM account.                                                   |
| `AWS_SECRET_ACCESS_KEY`  | ecret key associated with the access key. This is essentially the "password" for the access key. |
| `AWS_REGION`             | The AWS Region to send the request to.                                                           |



#### Google Cloud Platform

| Name                                  | Value                                   |
|---------------------------------------|-----------------------------------------|
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | Extracted Google credentials file JSON. |

#### Azure
| Name                  | Value                                                             |
|-----------------------|-------------------------------------------------------------------|
| `AZURE_TENANT_ID`     | The Azure Active Directory tenant (directory) ID.                 |
| `AZURE_CLIENT_ID`     | The client (application) ID of an App Registration in the tenant. |
| `AZURE_CLIENT_SECRET` | A client secret that was generated for the App Registration.      |