provider "aws" {
  region = ""
}

module "rdd-agent" {
  source = "./aws/ecs"

  vpc_id                       = ""
  private_subnet_ids           = ["", ""]
  datagrail_subdomain          = "<your_subdomain>.datagrail.io"
  credentials_manager          = "AWSSecretsManager"
  integration_credentials_arns = [""]
  agent_image_uri              = "338780525468.dkr.ecr.us-west-2.amazonaws.com/datagrail-rdd-agent:v0.7.3"
  cluster_arn                  = ""
  datagrail_api_key            = var.datagrail_api_key
}