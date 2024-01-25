# API Proxy Connector

Use the API Proxy connector to invoke internal or third-party REST APIs to perform data subject access, deletion, or identifier retrieval requests.

## Connector Configuration
The API Proxy connector follows the standard connector schema outlined in the `connectors` root directory.

### 🧐 Queries 
The `access`, `deletion`, and `test` queries are an array of objects.

The `identifiers` queries are defined in a single object with each key being the name of the identifier to retrieve, and the value of an array of objects. You must first create an alternate identifier in your DataGrail instance by following [this](https://docs.datagrail.io/docs/request-manager/request-processing/multi-id-setup) article. The name of the identifier in the Agent configuration is a snake_case version of what you named the identifier in DataGrail e.g. "Phone Number" would be `"phone_number"`

All query objects should have the below attributes:

| Name                              | Type          | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|-----------------------------------|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `url` (required)                  | string        | The URL of the API endpoint. Substitutions to be made with identifiers or values stored in your credential manager can be indicated with the variable name surrounded by curly brackets e.g.  `"url": "https://api.acme.com/v1/dsr/access?email={email}"`                                                                                                                                                                                                            |
| `headers` (optional)              | object        | The headers to include in the request. Set as necessary. Substitutions to be made with identifiers or values stored in your credential manager can be indicated with the variable name surrounded by curly brackets e.g.  `"headers": {"Authorization": "Basic {variable}"}`                                                                                                                                                                                         |
| `body` (optional)                 | string        | The body to include in the request. Set as necessary. Substitutions to be made with identifiers or values stored in your credential manager can be indicated with the variable name surrounded by curly brackets e.g.  `"body": "{{\"email\": \"{email}\"}}"`.  <br/><br/>   **Note:**  Double curly braces should be used to escape a curly brace to keep it in the payload of the request e.g. the above body would result in  `{"email": "<data subject email>"}` |
| `verb` (required)                 | string        | The HTTP request method for the API call. All HTTP methods are supported.                                                                                                                                                                                                                                                                                                                                                                                            |
| `verify_ssl` (required)           | string        | Determines whether to verify the SSL certificate of the URL. Accepted values are `"true"` or `"false"`.                                                                                                                                                                                                                                                                                                                                                              |
| `valid_response_codes` (optional) | array[number] | An array of status codes that the Agent should consider successful. The default value is `[200]`.  <br/><br/>  **Note:** The Agent will not handle instances of a data subject not existing any differently than a successful access, deletion, or identifier retrieval request. If the API returns a 404, for example, when a data subject does not exist, 404 should be added to the array of valid response code.                                                 |

### 🧪 Test Query
The API Proxy connector **requires** a `test` query (or queries) to determine liveness of the API being invoked. The endpoint must return a 200 status code to pass the health check.

### 🔑 Credentials
Credentials to include in the request will be stored in JSON format in your preferred credentials manager. The key/value pairs in the secret will be dictated by substitutions you need to make in your headers.
If the API uses Basic Authentication, for example, the headers in the configuration for the connector would be set as `"headers": {"Authorization": Basic "{credentials}"`, where a
key of `credentials` would be set to the credentials value, like so: `{"credentials": "<base64 encoded username:password>"}`

Tags and other settings should be set as necessary.

Copy the location of the secret (e.g. Amazon ARN) and insert it in as the value of the `credentials_location` key of the connector.

_Example Configuration:_
```json
    {
        "name": "User Service",
        "uuid": "44d9e703-b8cf-40a8-a138-3cc110319b0d",
        "capabilities": ["privacy/access", "privacy/delete", "privacy/identifiers"],
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

The API Proxy connector requires the following criteria to be met.

### 🪪 Authentication

The API proxy connector supports static token-based authentication. An access token must be pre-generated to be used to 
authenticate requests.

### 🤝 Request-Response
##### Flow

The API must employ a synchronous response flow whereby all operations occur over a single open connection.

Each request must be stateless and perform deletion, identifier, or data retrieval without any context of previously 
executed queries.

##### Response Format

###### Access Requests

The response body of an access request must be an array of objects. The value of each key can be of any datatype, including arrays and nested objects. Each object in the array will be converted into a separate file for your data subject.

The environment variable `LOGLEVEL` can be adjusted to `DEBUG` to get more detailed feedback if responses are malformed. Be aware that this level of logging has the potential to expose sensitive data. 

_Example Access Response:_

`HTTP/1.1 200 OK`

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

###### Deletion Request
The status code is the only signal used to determine if a deletion request was successful. A body can be included for logging purposes but will not propagate to the DataGrail platform.

_Example Access Response:_

`HTTP/1.1 200 OK`

```json
{
    "status": "completed",
    "message": "This response is for logging purposes"
}
```

###### Identifier Request
The response body of an identifier retrieval request must be an array of objects with the blow key/value pair.
```json
[
    {
      "<identifier category key>": "<identifier value>"
    }
]
```
The identifier category key is a snake_cased version of the identifier category that the identifier is assigned in the DataGrail application.

### Methods
All HTTP request methods are supported.

### Headers and Body
The headers and body of the request can contain anything of your choosing. The query configuration serves as the 
template for the request where the content required for the request can be specified. 