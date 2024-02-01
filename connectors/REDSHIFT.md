# Redshift Connector

#### Query Syntax and Parameter Binding
All queries are query strings that follow standard Redshift query syntax. 

Identifiers are passed individually to queries and are bound to the variables in the operation. Variables are specified using the [pyformat](https://peps.python.org/pep-0249/#paramstyle) parameter style (e.g. `...WHERE name = %(name)s` where `name` is the identifier name such as`email`).

#### Best Practices
For ease of maintainability and readability, it is suggested that the various queries be stored procedures. This allows for the underlying queries to be modified in Redshift without needing to modify the agent configuration, and for the query lists to be easily readable, especially in the case of complex joins.

#### Secret Creation

Create a new secret in JSON format in your preferred credentials manager with the following key/value pairs:
```json
{
    "user": "<DB username>",
    "password": "<DB password>",
    "host": "<server domain name or IP address>",
    "port": "<port, e.g. 5432>",
    "database": "<DB, e.g. BikeStores>"
}
```
Tags and other settings, please set as necessary.

Copy the location of the secret (e.g. Amazon ARN) and insert it in as the value of the `credentials_location` key of the connector.


_Example Configuration:_
```json
    {
        "name":"Metrics DWH",
        "uuid":"e887952b-4bde-4344-bd1d-c9a46805ebed",
        "capabilities":["privacy/access","privacy/delete","privacy/identifiers"],
        "mode":"live",
        "connector_type":"Redshift",
        "queries":{
            "identifiers": {
                "phone_number": [
                    "call get_phone_number(%(email)s)"
                ]
            },
            "access":["call dsr('access', %(email)s)"],
            "delete":["call dsr('delete', %(email)s)"]
        },
       "credentials_location":"arn:aws:secretsmanager:Region:AccountId:secret:datagrail.redshift"
    }
```

Insert the above, when completed, into the `connections` array in the `DATAGRAIL_AGENT_CONFIG` variable.
