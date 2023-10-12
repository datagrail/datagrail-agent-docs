# Configuration for API Proxy Connector

## Secrets Manager (AWS)

STEP 1: Create a new secret. Use the following to set it up:

    Secret Type: "Other type of secret"
    Key/value pairs:
        variable; see explanation below
    Secret name: <name for the secret>
    Description: <description for the secret>

Tags and other settings, please set as necessary.

**key/value pairs**: These are based on what substitutions you need in your queries.
For instance you may use something like a header:

`"headers": {"Api-Key": "{Api-Key}"` in your configuration, in which case enter a
key of `Api-Key` with a value set to the api-key header value.

When finished, please copy the ARN (Amazon Resource Name).

STEP 2: Create the configuration

    {
        "name":"Accounts DB",
        "uuid":"<create>",
        "capabilities":["privacy/access","privacy/delete","privacy/identifiers"],
        mode":"live",
        "connector_type":"APIProxy",
        "queries":{
            "identifiers": {
                "phone_number": [{
                    "url": "http://local-api-proxy:9080/v0/identifiers/get-phone",
                    "headers": {
                        "Customer-Api-Key": "{Customer-Api-Key}"
                    },
                    "body": "{{\"Email\": \"{email}\"}}",
                    "verb": "POST",
                    "verify_ssl": "false",
                    "identifier": "email"
                }]
            },
            "access":[
                {
                    "url": "http://10.1.18.199:8000/v0/right-to-access",
                    "headers": {"Api-Key": "{Api-Key}"},
                    "body": "{{\"TargetUserID\": {TargetUserId} , \"AgentUserID\": {AgentUserId}}}",
                    "verb": "POST",
                    "verify_ssl": "false",
                    "identifier": "email"
                }
            ],
            "delete":[]
        },
       "credentials_arn":"<secret ARN from above>"
    }

The UUID can be generated at, e.g. [UUID Generator](https://www.uuidgenerator.net/)

The access, delete and identifier queries are API calls, and as we're using python,
the `{email}` will be replaced with the email address or other identifier that gets passed in.

## System Requirements
### Authentication

The API proxy connector supports static token-based authentication. An access token must be pre-generated to be used to 
authenticate the request.

### Request-Response Flow
Each request must be stateless and perform deletion, identifier, or data retrieval without any context of previously 
executed queries.

The API called must support a synchronous response whereby all data is retrieved or deleted over an open connection.

The format of the response must be a list of objects as seen below:
```json
[
    {
        "column_name": "value",
        "column_name": "value",
        ...
    },
    {
        "column_name": "value",
        "column_name": "value",
        ...
    },
]
```

### Methods
The DataGrail agent allows for any method supported by Python’s requests library.

### Headers and Body
The headers and body of the request can contain anything of your choosing. The query configuration serves as the 
template for the request where the content required for the request can be specified. 

