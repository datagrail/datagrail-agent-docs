# Connector Configuration

## Overview

The DataGrail Request Manager Agent establishes connections to internal systems through a set of componentized integrations. DataGrail provides and is constantly expanding a standard set of integrations for use with common systems (databases, APIs, etc), however, the DataGrail Agent is designed to be extended through the use of custom components to encompass any needs specific to your organization. These are developed as Python modules that the DataGrail Agent will automatically discover and connect to using the defined configurations.

## Setup

Each connector is defined as an object in the `connections` array in the `DATAGRAIL_AGENT_CONFIG` environment variable. All connector configurations follow the same schema and required parameters, but the parameter binding syntax of the queries, and credentials/connection formats will differ. Refer to the connection's respective document for more information.

### Connector Object Parameter Definitions

| Name | Type | Description |
|------|:----:|-------------|
| `name`                 | String | The friendly name of the target system. This string will be displayed in the request results inside DataGrail. The name should be ASCII-only. |
| `uuid`                 | UUID   | The UUID associated with the connection. This should be a v4 UUID and should be unique per connection. You can use a service like [UUID Generator](https://www.uuidgenerator.net/) to obtain these easily. |
| `capabilities`         | Array  | Specifies the capabilities the connection should be used for. A connection should contain at least one capability. <br /><br />  Valid entries are: <br />  `"privacy/access"` - used to process data access requests. <br />  `"privacy/delete"` - used to process deletion requests. <br />  `"privacy/identifiers"` - used to process identifier retrieval requests. |
| `mode`                 | String | Indicates the status of the connection. The mode `"test"` should be used for a connection that is not ready for use by DataGrail in service of privacy requests. Otherwise, the mode should be set to `"live"`. |
| `connector_type`       | String | This field is used to configure the connector that DataGrail should use for the system connection. The adapter must be in the set of supported system types. |
| `queries`              | Object | Query syntax varies based on the target system. Refer to the connector-specific documentation in this directory for the proper syntax and requirements. |
| `credentials_location` | String | Location of the secret (e.g. AWS ARN) which should contain the credentials associated with the connection. The format of the credentials is specific to the target system but is generally contained in a JSON-encoded dictionary stored in the secret. For examples specific to your system, see the specific connector documentation. |

### Example Connector Configuration

```json
{
  "name": "Users Database",
  "uuid": "<create UUID>",
  "capabilities": ["privacy/access", "privacy/delete", "privacy/identifiers"],
  "mode": "live",
  "connector_type": "Postgres",
  "queries": {
      "identifiers": {"<identifier name>": ["<identifier query>"]},
      "access": ["<access query>"],
      "delete": ["<deletion query>"]
  },
  "credentials_location": "<secret location e.g. Amazon ARN>"
}
```
