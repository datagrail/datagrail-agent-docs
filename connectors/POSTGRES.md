# Configuration for PostgreSQL

#### Secret Creation

Create a new secret in JSON format in your preferred credentials manager with the following key/value pairs:
```json
{
    "user": "<DB username>",
    "password": "<DB password>",
    "host": "<server domain name or IP address>",
    "port": "<port, e.g. 5432>",
    "dbname": "<DB, e.g. BikeStores>"
}
```
Tags and other settings, please set as necessary.

Copy the location of the secret (e.g. Amazon ARN) and insert it in as the value of the `credentials_location` key of the connector.

#### Query Syntax and Parameter Binding
The `access`,`delete` and `identifiers` queries follow standard Snowflake query syntax and support built-in functions. 

Identifiers are passed individually to the queries and are bound to the variables in the operation. Variables are specified using `%(name)s` parameter style ([PEP 249 pyformat paramstyle](https://peps.python.org/pep-0249/#paramstyle)), where `name` is the identifier name (e.g. `email`).

#### Best Practices
For ease of maintainability and readability, it is suggested that the various queries be stored procedures. This allows for the underlying queries to be modified in Snowflake without needing to modify the agent configuration, and for the query lists to be easily readable, especially in the case of complex joins.
```json
    {
        "name":"Accounts DB",
        "uuid":"e887952b-4bde-4344-bd1d-c9a46805ebed",
        "capabilities":["privacy/access","privacy/delete","privacy/identifiers"],
        "mode":"live",
        "connector_type":"Postgres",
        "queries":{
            "identifiers": {
                "phone_number": [
                    "SELECT phone FROM customers WHERE email=%(email)s"
                ]
            },
            "access":["SELECT * FROM sales.staffs WHERE email = %(email)s"],
            "delete":["DELETE FROM sales.staff WHERE = %(email)s"]
        },
       "credentials_location":"arn:aws:secretsmanager:Region:AccountId:secret:datagrail.postgres"
    }
```
Insert the above, when completed, into the `connections` array in the `DATAGRAIL_AGENT_CONFIG` variable.

