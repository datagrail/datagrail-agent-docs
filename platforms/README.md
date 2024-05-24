# Setup

## Network Communication Requirements

The Agent does not support internal TLS termination, and requires the use of a load balancer or another form of TLS
termination. TLS 1.2+ is required to provide secure communication between services.

Ingress will be made to the Agent API over port 443 and will arrive from our VPC IP: `52.36.177.91`. Inbound requests
from any other source should be rejected.

The Agent will make network requests to the systems you have configured. In addition to these systems, it will also call
back to the DataGrail API via TLS at:

```http
https://<customer-name>.datagrail.io
```

It will also place request results in your cloud storage bucket (AWS S3, Google Cloud Storage, or Azure Blob Storage).

## Installation

This folder contains installation scripts and instructions for the common platforms that DataGrail supports.

### Configuration

[DataGrail Agent Configuration](../CONFIGURATION.md) - Configuration instructions for `datagrail-rm-agent`

### Platforms

- [Amazon Web Services (AWS)](AWS_ECS_README.md)
- [Azure](AZURE_README.md)
- [Google Cloud Platform (GCP)](GCP_README.md)
- [Backblaze B2](BACKBLAZE_B2.md)

### Connectors

- [BigQuery](../connectors/BIG_QUERY.md)
- [MySQL](../connectors/MYSQL.md)
- [Oracle DB](../connectors/ORACLE_DB.md)
- [PostgreSQL](../connectors/POSTGRES.md)
- [Redshift](../connectors/REDSHIFT.md)
- [Snowflake](../connectors/SNOWFLAKE.md)
- [SQL Server](../connectors/SQL_SERVER.md)
- [SSH Client](../connectors/SSH.md)
- [API Proxy](../connectors/API_PROXY.md)
