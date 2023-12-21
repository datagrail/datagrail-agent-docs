# Configuration for MySQL

### Secret Creation

Create a new secret in your preferred credentials manager in JSON format with the following key/value pairs:
```json
{
    "user": "<DB username>",
    "password": "<DB password>",
    "server": "<server domain name or IP address>",
    "port": "<port, e.g. 3306>",
    "database": "<DB, e.g. BikeStores>",
}
```
Tags and other settings, please set as necessary.

When finished, copy the location of the secret (e.g. Amazon ARN) and place it in the `credentials_location` parameter of the connector.

#### UUID Creation
The UUID can be generated using this [UUID Generator](https://www.uuidgenerator.net/)

#### Parameter Binding
The `access`,`delete` and `identifiers` queries are SQL statements to execute, and the `<identifier_name>` in `%(<identifier_name>)s`
will be replaced with the email address or other identifier that gets passed in.

Insert the configuration, when completed, into the `DATAGRAIL_AGENT_CONFIG` variable.

#### Best Practices
For ease of maintainability and readability, it is suggested that the various queries be stored procedures. This allows for the underlying queries to be modified in MySQL without needing to modify the agent configuration, and for the query lists to be easily readable, especially in the case of complex joins. 

### Example MySQL Connector Configuration
```json
{
    "name": "Customer DB",
    "uuid": "d2ceb82a-618f-4872-8ba4-2d0108918301",
    "capabilities": ["privacy/access", "privacy/identifiers"],
    "mode": "live",
    "connector_type": "MySQL",
    "queries":{
        "identifiers": {
            "phone_number": [
                "CALL get_phone_by_email(%(email)s)"
            ]
        },
        "access":["CALL access_customer_by_email(%(email)s)"],
        "delete":[]
    },
   "credentials_location":"arn:aws:secretsmanager:Region:AccountId:secret:datagrail.mysql"
}
```
