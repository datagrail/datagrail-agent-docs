# Google BigQuery

#### Query Syntax and Parameter Binding
All queries are query strings that should follow standard BigQuery query syntax. 

Identifiers are passed individually to queries and are bound to the variables in the operation. Variables are specified using the [pyformat](https://peps.python.org/pep-0249/#paramstyle) parameter style (e.g. `...WHERE name = %(name)s` where `name` is the identifier name such as`email`).

#### Best Practices
For ease of maintainability and readability, it is suggested that the various queries be stored procedures. This allows for the underlying queries to be modified in BigQuery without needing to modify the agent configuration, and for the query lists to be easily readable, especially in the case of complex joins.

#### Secret Creation

Create a new secret in JSON format in your preferred credentials manager with the following key/value pairs:
```json
{
    "project_id": "<project ID>"
}
```
Labels, replication, and other settings, please set as necessary.

Copy the name of the secret and insert it in as the value of the `credentials_location` key of the connector.

_Configuration Example:_
```json
    {
        "name": "Metrics",
        "uuid": "<create UUID>",
        "capabilities": ["privacy/access","privacy/delete", "privacy/identifiers"],
        "mode": "live",
        "connector_type": "BigQuery",
        "queries": {
          "identifiers": {
                "phone_number": [
                    "CALL metrics.get_phone_number(%(email)s)"
                ]
            },
            "access": ["CALL metrics.dsr_operation('access', %(email))"],
            "delete": ["CALL metrics.dsr_operation('delete', %(email))"]
        },
        "credentials_location":"BigQuery"
    }
```

