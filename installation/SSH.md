# Configuration for SSH Connector

## Secrets Manager (AWS)

STEP 1: Create a new secret. Use the following to set it up:

    Secret Type: "Other type of secret"
    Key/value pairs:
        username: <username>
        password: (optional)<password>
        private_key: (preferred over password) <PEM encoded private key>
        server: <hostname or IP Address of server>
        port: (optional)<port to connect to, defaults to 22>
    Secret name: <name for the secret>
    Description: <description for the secret>

Tags and other settings, please set as necessary.

When finished, please copy the ARN (Amazon Resource Name).

STEP 2: Create the configuration

    {
        "name":"Accounts DB",
        "uuid":"<create>",
        "capabilities":["privacy/access","privacy/delete","privacy/identifiers"],
        mode":"live",
        "connector_type":"SSH",
        "queries":{
            "access":["./fake.py {email}"],
            "delete":[]
        },
       "credentials_location":"<secret ARN from above>"
    }

The UUID can be generated at, e.g. [UUID Generator](https://www.uuidgenerator.net/)

The access, delete and identifier queries are command line commands, and as we're using python,
the {} will be replaced with the email address or other identifier that gets passed in.

In the above example, we would call `./fake.py example@example.com`, with the caveat that
the email address is run through [shlex.quote](https://docs.python.org/3/library/shlex.html#shlex.quote).

Insert the above, when completed, into [agent_config.json](examples/agent_config.json).

## Response Format

Results should be reported via `stdout` and the expected format is JSON. The JSON schema can be found in 
`/connectors/connector_ssh.py`, which can be generally described as a list of dictionaries. The environment variable `LOGLEVEL` can be adjusted to `DEBUG` to get more detailed feedback if responses are malformed. Be aware that this level of logging has the potential to expose sensitive data. 

Some examples of properly formatted responses:
Example A:
```
[
    {
        "first_name": "Howard", 
        "last_name": "Fornortoner", 
        "address1": "123 any street"
    },{
        "first_name": "Susan", 
        "last_name": "Fornortoner", 
        "address1": "123 any street"
    }
]
```
Example B:
```
[
    {
        "status": "success
    }
]
```
