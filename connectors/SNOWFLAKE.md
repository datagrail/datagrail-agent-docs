# Configuration for Snowflake

#### Secret Creation

Create a new secret in JSON format in your preferred credentials manager with the following key/value pairs:
```json
{
    "user": "<DB username>",
    "password": "<DB password>",
    "account": "<Snowflake Account, e.g. EXA*****>",
    "warehouse": "<Snowflake Warehouse, e.g. COMPUTE_WH>",
    "database": "<Snowflake DB, e.g. SNOWFLAKE_SAMPLE_DATA>",
}
```
Tags and other settings, please set as necessary.

Copy the location of the secret (e.g. Amazon ARN) and insert it in as the value of the `credentials_location` key of the connector.

#### Query Syntax and Parameter Binding
The `access`,`delete` and `identifiers` queries follow standard Snowflake query syntax and support built-in functions. 

Identifiers are passed individually to the queries and are bound to the variables in the operation. Variables are specified using `%(name)s` parameter style (PEP 249 pyformat paramstyle), where `name` is the identifier name (e.g. `email`).

#### Best Practices
For ease of maintainability and readability, it is suggested that the various queries be stored procedures. This allows for the underlying queries to be modified in Snowflake without needing to modify the agent configuration, and for the query lists to be easily readable, especially in the case of complex joins.

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
                    "SELECT C_PHONE_NUMBER FROM TPCDS_SF100TCL.CUSTOMER where C_EMAIL_ADDRESS =  %(email)s"
                ]
            },
            "access": ["SELECT * FROM TPCDS_SF100TCL.CUSTOMER where C_EMAIL_ADDRESS =  %(email)s"],
            "delete": ["DELETE FROM TPCDS_SF100TCL.CUSTOMER where C_EMAIL_ADDRESS =  %(email)s"]
        },
        "credentials_location": "arn:aws:secretsmanager:Region:AccountId:secret:datagrail.snowflake"
    }
```

When complete, insert the above into the `connections` array in the `DATAGRAIL_AGENT_CONFIG` variable.
