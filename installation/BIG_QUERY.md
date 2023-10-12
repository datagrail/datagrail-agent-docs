# Configuration for Google BigQuery

## Secrets Manager (GCP)

STEP 1: Create a new secret. Use the following to set it up:

    Secret name: <name for the secret>
    Secret Value:
        {"project_id": "<project id>"}

Labels, replication, and other settings, please set as necessary.

When finished, please copy the *name* of the secret.

STEP 2: Create the configuration

    {
        "name":"Accounts DB",
        "uuid":"<create UUID>",
        "capabilities":["privacy/access","privacy/delete"],
        mode":"live",
        "connector_type":"BigQuery",
        "queries":{
            "access":["SELECT * FROM TPCDS_SF100TCL.CUSTOMER where C_EMAIL_ADDRESS = %(email)"],
            "delete":[]
        },
        "credentials_location":"<secret name from above>"
    }

The UUID can be generated at, e.g. [UUID Generator](https://www.uuidgenerator.net/)

The access and delete queries are SQL statements to execute, and the `%(<identifier name>)s`
will be replaced with the email address or other identifier that gets passed in.

Insert the above, when completed, into [agent_config.json](examples/agent_config.json).
