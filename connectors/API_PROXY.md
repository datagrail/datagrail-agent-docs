# Configuration for API Proxy Connector

The API Proxy connector can be used to call a REST API to perform access, deletion, or identifier retrieval requests. The API can be anything from an internal service to a third-party application.

### Secret Creation

Create a new secret in JSON format in your preferred credentials manager. The key/value pairs in the secret are based on what substitutions you need in your queries.
For example, if the API uses Basic Authentication, the headers in the configuration for the connector would be set as `"headers": {"Authorization": Basic "{credentials}"`, where a
key of `credentials` would be set to the credentials value in your credentials manager, like so: `{"credentials": "<base64 encoded username:password>"}`

Tags and other settings should be set as necessary.

Copy the location of the secret (e.g. Amazon ARN) and insert it in as the value of the `credentials_location` key of the connector.

### Query Configuration Creation
The queries in the API Proxy connector are an array of objects that require the following attributes:

`url` (string): The URL of the API endpoint.

`headers` (object): The headers to include in the request. Substitutions to be made with identifiers or values stored in your credentials manager can be indicated with curly brackets.

`body` (string): The body to include in the request. Substitutions to be made with identifiers or values stored in your credentials manager can be indicated with curly brackets. 

`verb` (string): The HTTP request method for the API call. All HTTP methods are supported.

`verify_ssl` (string): Determines whether to verify the SSL certificate of the URL. Accepted values are `"true"` or `"false"`.

### Health Check
The API Proxy connector requires a query in the `test` block to be used to determine liveness of the API. The endpoint must return a 200 status code to pass the health check.

_Example Configuration:_
```json
    {
        "name": "User Service",
        "uuid": "44d9e703-b8cf-40a8-a138-3cc110319b0d",
        "capabilities": ["privacy/access", "privacy/identifiers"],
        "mode": "live",
        "connector_type": "APIProxy",
        "queries": {
            "test": [
                {
                    "url": "https://api.acme.com/v0/health-check",
                    "headers": {
                        "Authorization": "Basic {credentials}"
                    },
                    "body": "",
                    "verb": "POST",
                    "verify_ssl": "true"
                }
            ],
            "identifiers": {
                "phone_number": [{
                    "url": "https://api.acme.com/v0/identifiers/get-phone",
                    "headers": {
                        "Authorization": "Basic {credentials}"
                    },
                    "body": "{{\"email\": \"{email}\"}}",
                    "verb": "POST",
                    "verify_ssl": "true"
                }]
            },
            "access":[
                {
                    "url": "https://api.acme.com/v0/users",
                    "headers": {
                        "Authorization": "Basic {credentials}"
                    },
                    "body": "{{\"email\": \"{email}}\"}",
                    "verb": "GET",
                    "verify_ssl": "true"
                }
            ],
            "delete": [
                {
                    "url": "https://api.acme.com/v0/users",
                    "headers": {
                        "Authorization": "Basic {credentials}"
                    },
                    "body": "{{\"email\": \"{email}}\"}",
                    "verb": "DELETE",
                    "verify_ssl": "true"
                }
            ]
        },
       "credentials_arn": "arn:aws:secretsmanager:Region:AccountId:secret:datagrail.user-service"
    }
```
When complete, insert the above into the `connections` array in the `DATAGRAIL_AGENT_CONFIG` variable.

## System Requirements
### Authentication

The API proxy connector supports static token-based authentication. An access token must be pre-generated to be used to 
authenticate the request.

### Request-Response Flow
Each request must be stateless and perform deletion, identifier, or data retrieval without any context of previously 
executed queries.

The API must also support a synchronous response whereby all data is retrieved or deleted over an open connection.

### Response Format
The format of the response must be an array of objects. The value of each key can be of any datatype, including arrays and nested objects. Each object in the array will be converted into a separate file for your data subject.

The environment variable `LOGLEVEL` can be adjusted to `DEBUG` to get more detailed feedback if responses are malformed. Be aware that this level of logging has the potential to expose sensitive data. 

_Example Reponse:_
```json
[
    {
        "first_name": "Homer",
        "last_name": "Simpson",
        "interests": [
          "Donuts",
          "Beer"
        ]
    },
    {
        "address_type": "Home",
        "address": {
          "street": "742 Evergreen Trace",
          "city": "Springfield",
          "state": "Oregon",
          "zip_code": "97403"
        }
    }
]
```

### Methods
All HTTP request methods are supported.

### Headers and Body
The headers and body of the request can contain anything of your choosing. The query configuration serves as the 
template for the request where the content required for the request can be specified. 

