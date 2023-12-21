# Configuration for SQL Server

## Secrets Manager (AWS)

STEP 1: Create a new secret. Use the following to set it up:

    Secret Type: "Other type of secret"
    Key/value pairs:
        user: <DB username>
        password: <DB password>
        server: <server domain name or IP address)
        port: <port, e.g. 1433>
        database: <DB, e.g. BikeStores>
    Secret name: <name for the secret>
    Description: <description for the secret>

Tags and other settings, please set as necessary.

When finished, please copy the ARN (Amazon Resource Name).

STEP 2: Create the configuration

    {
        "name":"Accounts DB",
        "uuid":"<create UUID>",
        "capabilities":["privacy/access","privacy/delete","privacy/identifiers"],
        mode":"live",
        "connector_type":"SQLServer",
        "queries":{
            "identifiers": {
                "phone_number": [
                    "select phone from customers where email=%(email)s"
                ]
            },
            "access":["SELECT * FROM sales.staffs where email = %(email)s"],
            "delete":[]
        },
       "credentials_location":"<secret ARN from above>"
    }

The UUID can be generated at, e.g. [UUID Generator](https://www.uuidgenerator.net/)

The access and delete queries are SQL statements to execute, and the ``%(<identifier name>)s``
will be replaced with the email address or other identifier that gets passed in.

Insert the above, when completed, into [agent_config.json](../examples/agent_config.json).
