# Configuration for SQL Server

#### Secret Creation

Create a new secret in JSON format in your preferred credentials manager with the following key/value pairs:
```json
{
    "user": "<DB username>",
    "password": "<DB password>",
    "server": "<server domain name or IP address>",
    "port": "<port, defaults to 1433>",
    "database": "<DB, e.g. BikeStores>",
}
```
Tags and other settings, please set as necessary.

Copy the location of the secret (e.g. Amazon ARN) and insert it in as the value of the `credentials_location` key of the connector.

#### Query Syntax and Parameter Binding
All queries are query strings that should follow standard SQL server query syntax. 

Identifiers are passed individually to the queries and are bound to the variables in the operation. Variables are specified using `%(name)s` parameter style ([PEP 249 pyformat paramstyle](https://peps.python.org/pep-0249/#paramstyle)), where `name` is the identifier name (e.g. `email`).

#### Best Practices
For ease of maintainability and readability, it is suggested that the various queries be stored procedures. This allows for the underlying queries to be modified in SQL Server without needing to modify the agent configuration, and for the query lists to be easily readable, especially in the case of complex joins.

_Configuration Example:_
```json
    {
        "name":"Accounts DB",
        "uuid":"6a058f35-c37b-423f-b418-4324725b5ff5",
        "capabilities":["privacy/access","privacy/delete","privacy/identifiers"],
        "mode":"live",
        "connector_type":"SQLServer",
        "queries":{
            "identifiers": {
                "phone_number": [
                    "SELECT phone FROM customers WHERE email=%(email)s"
                ]
            },
            "access":["SELECT * FROM sales.staffs WHERE email = %(email)s"],
            "delete":["DELETE FROM sales.staffs WHERE email = %(email)s"]
        },
       "credentials_location":"arn:aws:secretsmanager:Region:AccountId:secret:datagrail.snowflake"
    }
```
The UUID can be generated at, e.g. [UUID Generator](https://www.uuidgenerator.net/)

The access and delete queries are SQL statements to execute, and the ``%(<identifier name>)s``
will be replaced with the email address or other identifier that gets passed in.

Insert the above, when completed, into [agent_config.json](../examples/agent_config.json).
