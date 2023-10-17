# Setting Up Backblaze B2 as a Storage Backend

This will cover the specific settings for Backblaze B2 as a Storage Interface/Backend.

Please see the general setup guide in [AGENT CONFIGURATION](DATAGRAIL_AGENT_CONFIGURATION_README.md).

Example platform configuration using AWS Secrets Manager for secrets, and Backblaze B2 as a storage backend.

```json
  "platform": {
    "credentials_manager": {
      "provider": "AWSSecretsManager",
      "options": {}
    },
    "storage_manager": {
      "provider": "BackblazeB2",
      "options": {
          "bucket": "<your bucket>",
          "endpoint": "https://s3.us-west-004.backblazeb2.com",
          "region": "us-west-004"
      }
    }
```

Ensure that the bucket, endpoint, and region are all set according to
the values in the Backblaze Console;
[Backblaze's console/B2 settings documentation](https://help.backblaze.com/hc/en-us/articles/360047425453-Getting-Started-with-the-S3-Compatible-API).

Additionally, make sure to add the following environment values (as outlined in the AGENT CONFIGURATION link above):

```dotenv
AWS_ACCESS_KEY_ID=<Backblasze B2 keyID>
AWS_SECRET_ACCESS_KEY=<Backblasze B2 applicationKey>
```

alternately, change these to `BACKBLAZE_` prefixed variables to prevent conflict with existing AWS configuration (e.g. when using AWS Secrets Manager):

```dotenv
BACKBLAZE_ACCESS_KEY_ID=<Backblasze B2 keyID>
BACKBLAZE_SECRET_ACCESS_KEY=<Backblasze B2 applicationKey>
```
