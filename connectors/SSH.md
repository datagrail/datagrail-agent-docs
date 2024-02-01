# SSH Connector

The SSH connector can be used to create an SSH tunnel to a server and execute a command-line argument such as invoking a script to run access, deletion, and identifier retrieval operations.

#### Secret Creation

Create a new secret in JSON format in your preferred credentials manager with the following key/value pairs:
```json
{
    "username": "username>",
    "password": "(optional) <password>",
    "private_key": "(preferred over password) <PEM encoded private key>",
    "server": "<hostname or IP Address of server>",
    "port": "(optional) <port to connect to, defaults to 22>"
}
```
Tags and other settings, please set as necessary.

Copy the location of the secret (e.g. Amazon ARN) and insert it in as the value of the `credentials_location` key of the connector.

STEP 2: Create the configuration
```json
    {
        "name":"DSR Script",
        "uuid":"95e99cea-e402-499c-a6f8-0db6852ecfec",
        "capabilities":["privacy/access","privacy/delete"],
        "mode":"live",
        "connector_type":"SSH",
        "queries":{
            "access":["./dsr.py access {email}"],
            "delete":["./dsr.py delete {email}"]
        },
       "credentials_location":"<secret ARN from above>"
    }
```

The access, delete and identifier queries are command line arguments that support named argument placeholders to format the string with identifier values.

In the above example, for an access request for exampled@datagrail.io we would call `./dsr.py access example@datagrail.io`, with the caveat that
the email address is run through [shlex.quote](https://docs.python.org/3/library/shlex.html#shlex.quote).

When complete, insert the above into the `connections` array in the `DATAGRAIL_AGENT_CONFIG` variable.

## Response Format

Results should be reported via `stdout` and the expected format is JSON. The JSON schema can be generally described as an array of objects. Each object in the array will result in a separate file for you data subject.

The environment variable `LOGLEVEL` can be adjusted to `DEBUG` to get more detailed feedback if responses are malformed. Be aware that this level of logging has the potential to expose sensitive data. 

Some examples of properly formatted responses:

Example A:
```json
[
    {
        "first_name": "Howard", 
        "last_name": "Spears", 
        "address1": {
          "street": "123 Any Street",
          "city": "San Francisco",
          "state": "California",
          "zip_code": "92123"
        }
    },{
        "first_name": "Susan", 
        "last_name": "Spears", 
        "address1": {
          "street": "123 Any Street",
          "city": "San Francisco",
          "state": "California",
          "zip_code": "92123"
        }
    }
]
```
Example B:
```json
[
    {
        "status": "success"
    }
]
```
