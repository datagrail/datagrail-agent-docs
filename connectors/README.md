# Connectors

## Overview

The DataGrail Agent establishes connections to internal systems through a set of componentized integrations. DataGrail provides and is constantly expanding a standard set of integrations for use with common systems (databases, APIs, etc), however, the DataGrail Agent is designed to be extended through the use of custom components to encompass any needs specific to your organization. These are developed as Python modules that the DataGrail Agent will automatically discover and connect to using the defined configurations.

## Configuration

All connector configurations follow the same schema and required parameters, but the parameter binding syntax, and credentials/connection formats will differ. Refer to the connector's respective document for more information.

Each connection is defined as an object in the `connections` array in the Agent’s configuration environment variable. The general format of each connection object is outlined below, with connection-specific examples in their respective instructions document.
```json
{
  "name": "<friendly name of the  target system>",
  "uuid": "<create UUID>",
  "capabilities": ["<one or more of: privacy/access|privacy/delete|privacy/identifiers>"],
  "mode": "live|test",
  "connector_type": "<connector type, e.g. Snowflake, SQLServer, SSH>",
  "queries": {
      "identifiers": {"<identifier name>": ["<identifier query>"]},
      "access": ["<access query>"],
      "delete": ["<deletion query>"]
  },
  "credentials_location": "<secret location e.g. Amazon ARN>"
}
```