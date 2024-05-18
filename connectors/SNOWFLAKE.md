# Snowflake Connector

#### Query Syntax and Parameter Binding
All queries are query strings that should follow standard Snowflake syntax. 

Identifiers are passed individually to queries and are bound to the variables in the operation. Variables are specified using the [pyformat](https://peps.python.org/pep-0249/#paramstyle) parameter style (e.g. `...WHERE name = %(name)s` where `name` is the identifier name such as `email`).

#### Best Practices
For ease of maintainability and readability, it is suggested that the various queries be stored procedures. This allows for the underlying queries to be modified in Snowflake without needing to modify the agent configuration, and for the query lists to be easily readable, especially in the case of complex joins.

#### Secret Creation

It is advised to create a DataGrail Agent-specific Snowflake User or Role to scope the permissions to the operations that it needs to perform. 

Create a new secret with the users' credentials in JSON format in your preferred credentials manager with the following key/value pairs:
```json
{
    "user": "<DB username>",
    "password": "<DB password>",
    "account": "<Snowflake Account, e.g. EXA*****>",
    "warehouse": "<Snowflake Warehouse, e.g. COMPUTE_WH>",
    "database": "<Snowflake DB, e.g. SNOWFLAKE_SAMPLE_DATA>"
}
```
Tags and other settings, please set as necessary.

Copy the location of the secret (e.g. Amazon ARN) and insert it in as the value of the `credentials_location` key of the connector.

_Example Configuration:_
```json
    {
        "name": "Accounts DB",
        "uuid": "f237cdae-e8d1-4799-be0a-8a79c25e33de",
        "capabilities": ["privacy/access", "privacy/delete", "privacy/identifiers"],
        "mode": "live",
        "connector_type": "Snowflake",
        "queries": {
            "identifiers": {
                "phone_number": [
                    "CALL get_phone_number(%(email)s)"
                ]
            },
            "access": ["CALL dsr_operation('access', %(email)s)"],
            "delete": ["CALL dsr_operation('delete', %(email)s)"]
        },
        "credentials_location": "arn:aws:secretsmanager:Region:AccountId:secret:datagrail.snowflake"
    }
```

When complete, insert the above into the `connections` array in the `DATAGRAIL_AGENT_CONFIG` variable.
