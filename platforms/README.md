# Setup

## Network Communication Requirements

The agent service does not support internal TLS termination, configuring a load balancer or another form of TLS
termination is required. TLS 1.2+ is required to provide secure communication between services.

Ingress will be made to the agent API over port 443 and will arrive from our VPC IP: `52.36.177.91`. Inbound requests
from any other source should be rejected.

The agent will make network requests to the systems you have configured. In addition to these systems, it will also call
back to the DataGrail API via TLS at:

```
https://<customer-name>.datagrail.io
```

It will also place request results in your cloud storage bucket (AWS S3, Google Cloud Storage, or Azure Blob Storage)
over the Amazon API using Python’s boto3 package.

# Installation

This folder contains installation scripts and instructions for the common platforms DataGrail supports.

## Configuration

[DataGrail Agent Configuration](../CONFIGURATION.md) - Configuration instructions for `datagrail-rm-agent`

## Platforms

[AWS ECS](AWS_ECS_README.md) - Setup instructions for Amazon ECS

[AZURE](AZURE_README.md) - Setup instructions for Microsoft Azure

[GCP](GCP_README.md) - Setup instructions for Google Cloud

[BACKBLAZE](BACKBLAZE_B2.md) - Setup instructions for Backblaze B2

## Connectors

[BigQuery](../connectors/BIG_QUERY.md) - Instructions for setting up and configuring the BigQuery Connector

[MySQL](../connectors/MYSQL.md) - Instructions for setting up and configuring the MySQL Connector

[Oracle DB](../connectors/ORACLE_DB.md) - Instructions for setting up and configuring the Oracle DB Connector

[PostgreSQL](../connectors/POSTGRES.md) - Instructions for setting up and configuring the PostgreSQL Connector

[Redshift](../connectors/REDSHIFT.md) - Instructions for setting up and configuring the Redshift Connector

[Snowflake](../connectors/SNOWFLAKE.md) - Instructions for setting up and configuring the Snowflake Connector

[SQL Server](../connectors/SQL_SERVER.md) - Instructions for setting up and configuring the SQL Server Connector

[SSH Client](../connectors/SSH.md) - Instructions for setting up and configuring the SSH Connector

[API Proxy](../connectors/API_PROXY.md) - Instructions for setting up and configuring the API Proxy Connector
