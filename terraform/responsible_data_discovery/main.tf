provider "aws" {
  region  = ""
}

module "rdd-agent" {
  source = "./aws/ecs"

  vpc_id              = ""
  private_subnet_ids  = ["", ""]
  datagrail_subdomain = "solutions.datagrail.io"
  credentials_manager = "AWSSecretsManager"
  agent_image_uri     = "338780525468.dkr.ecr.us-west-2.amazonaws.com/datagrail-rdd-agent:v0.7.3"
  cluster_arn = ""
  datagrail_api_key = var.datagrail_api_key
  integration_credentials_arns = ["arn:aws:secretsmanager:us-west-2:158714794554:secret:datagrail-rdd-agent.snowflake-bjqVnb"]
}