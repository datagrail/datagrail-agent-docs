# DataGrail Agent Configuration

The DataGrail Agent configuration variables dictate the target systems the Agent should connect to, what operations should be performed, as well as other metadata to instruct Agent behavior. 

To configure the DataGrail Agent properly, you will need to:
* Determine the system(s) you want the Agent to connect to, their associated connector(s) and the applicable queries. 
* Create and store secrets for:
  * Each connector. 
  * The OAuth Client Credentials for the Agent to authorize operations by the DataGrail application. 
  * The callback token to authenticate the Agent's callbacks to the DataGrail platform. 
* Set the environment variable(s).

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
"token": "<your DataGrail provided token>"
}
```
### Environment Variables

| Name                     | Type   | Description                                                                                           |
|--------------------------|--------|-------------------------------------------------------------------------------------------------------|
| `DATAGRAIL_AGENT_CONFIG` | Object | JSON object that contains all metadata about connectors, credentials locations, cloud storage, etc.   |


#### `DATAGRAIL_AGENT_CONFIG` Object Schema:
| Name                                   | Type   | Description                                                                                                                                                                                                                                                                     |
|----------------------------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `connections`                          | Array  | The connections array defines target systems that the agent should connect to and their capabilities.   It is also used to map and classify system results back into DataGrail. See the [Connectors](/connectors) documentation for specifics on each connector configurations. |
| `customer_domain`                      | String | Your DataGrail-registered customer domain e.g. acme.datagrail.io                                                                                                                                                                                                                |
| `datagrail_agent_credentials_location` | String | The location(e.g. AWS Secrets Manager ARN) of the [OAuth Client Credentials](#OAuth Client Credentials).                                                                                                                                                                        |
| `datagrail_credentials_location`       | String | The location of the [DataGrail Callback Token](#DataGrail Callback Token) used to make callback requests to the DataGrail API.                                                                                                                                                  |
| `platform`                             | Object | The secrets/credentials and cloud storage platforms used to deploy the Agent. The `platform` object requires two blocks: `credentials_manager` and `storage_manager`. Refer to their respective directories for configuration instructions                                      |
| `redis_url`                            | String | Optional field for multi-node deployments.The Agent needs persistent storage during its process lifetime thus, if you have multiple nodes, they need to share a Redis instance.                                                                                                 |

_**Example Configuration:**_
```json
{
    "connections": [
        {
            "name": "Users Database",
            "uuid": "91e3f3a4-d669-46a8-ab76-af88ca790b62",
            "capabilities": [
                "privacy/access",
                "privacy/delete",
                "privacy/identifiers"
            ],
            "mode": "live",
            "connector_type": "Postgres",
            "queries": {
                "identifiers": {
                    "phone_number": [
                        "SELECT phone_number FROM public.users WHERE email = %(email)s"
                    ]
                },
                "access": [
                    "CALL"
                ],
                "delete": [
                    "<deletion queries>"
                ]
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
                "optional": "sadfsdf"
            }
        },
        "storage_manager": {
            "provider": "<GCPCloudStore|AWSS3|AzureBlob|BackblazeB2>",
            "options": {
                "bucket": "<bucket name, required>",
                "optional": ""
            }
        }
    }
}
```
If deploying the Agent locally for testing, or not using Role Based Access Controls in your cloud provider, the following environment variables need set.
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