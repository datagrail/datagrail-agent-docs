# Configuration for Google BigQuery

#### Secret Creation

Create a new secret in JSON format in your preferred credentials manager with the following key/value pairs:
```json
{
    "project_id": "<project ID>"
}
```
Labels, replication, and other settings, please set as necessary.

Copy the name of the secret and insert it in as the value of the `credentials_location` key of the connector.

#### Query Syntax and Parameter Binding
The `access`,`delete` and `identifiers` queries follow standard BigQuery query syntax and support built-in functions. 

Identifiers are passed individually to the queries and are bound to the variables in the operation. Variables are specified using `%(name)s` parameter style ([PEP 249 pyformat paramstyle](https://peps.python.org/pep-0249/#paramstyle)), where `name` is the identifier name (e.g. `email`).

#### Best Practices
For ease of maintainability and readability, it is suggested that the various queries be stored procedures. This allows for the underlying queries to be modified in BigQuery without needing to modify the agent configuration, and for the query lists to be easily readable, especially in the case of complex joins.

_Configuration Example:_
```json
    {
        "name": "Metrics",
        "uuid": "<create UUID>",
        "capabilities": ["privacy/access","privacy/delete"],
        "mode": "live",
        "connector_type": "BigQuery",
        "queries": {
            "access": ["SELECT * FROM TPCDS_SF100TCL.CUSTOMER where C_EMAIL_ADDRESS = %(email)"],
            "delete": ["DELETE FROM TPCDS_SF100TCL.CUSTOMER where C_EMAIL_ADDRESS = %(email)"]
        },
        "credentials_location":"BigQuery"
    }
```

