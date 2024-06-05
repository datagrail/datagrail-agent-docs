terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.21.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  default_tags {
    tags = var.tags
  }
  profile = "admin-158714794554"
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnet" "private" {
  id = var.private_subnet_id
}

data "aws_route_table" "private" {
  subnet_id = var.private_subnet_id
}

locals {
  rdd_agent_config               = jsondecode(file("../rdd-agent-config.json"))
  secrets_manager                = local.rdd_agent_config.platform.credentials_manager.provider
  datagrail_credentials_location = local.rdd_agent_config.datagrail_credentials_location
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-ecs-task-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "agent_task_policy" {
  statement {
    sid = "SecretsManagerGetSecretValue"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [local.datagrail_credentials_location]

  }
}

resource "aws_iam_policy" "agent_task" {
  name   = "agent_task_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.agent_task_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.agent_task.arn
}

resource "aws_cloudwatch_log_group" "ecs_task_logger" {
  name = "/ecs/${var.project_name}"

  retention_in_days = var.cloudwatch_log_retention
}

resource "aws_ecs_task_definition" "datagrail_agent" {
  family                   = var.project_name
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = var.agent_container_cpu
  memory                   = var.agent_container_memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  container_definitions = jsonencode([
    {
      name = var.project_name
      logConfiguration = {
        "logDriver" = "awslogs"
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_task_logger.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "/ecs"
        }
      },
      portMappings = [
        {
          "hostPort"      = 80
          "protocol"      = "tcp"
          "containerPort" = 80
        }
      ],
      command = [
        "supervisord",
        "-n",
        "-c",
        "/etc/rdd.conf"
      ],
      environment = [
        { "name" = "DATAGRAIL_AGENT_CONFIG", "value" = file("../rdd-agent-config.json") }
      ]
      cpu              = 0
      workingDirectory = "/app"
      image            = var.agent_image_uri
      healthCheck = {
        "retries" = 3
        "command" = [
          "CMD-SHELL",
          "test -f /healthy"
        ],
        "timeout"     = 5
        "interval"    = 30
        "startPeriod" = 1
      },
      essential = true
    }
  ])
}

resource "aws_security_group" "service_security_group" {
  name   = "${var.project_name}-service-security-group"
  vpc_id = data.aws_vpc.this.id
}

resource "aws_security_group_rule" "service_egress_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.service_security_group.id
  cidr_blocks       = var.service_egress_cidr
}

resource "aws_security_group" "vpc_endpoint" {
  count  = var.create_vpc_endpoints == true ? 1 : 0
  name   = "${var.project_name}-vpce-security-group"
  vpc_id = data.aws_vpc.this.id
}

resource "aws_security_group_rule" "vpc_endpoint" {
  count             = var.create_vpc_endpoints == true ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.vpc_endpoint[0].id
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
}

resource "aws_vpc_endpoint" "cloudwatch" {
  count              = var.create_vpc_endpoints == true ? 1 : 0
  vpc_id             = data.aws_vpc.this.id
  service_name       = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [data.aws_subnet.private.id]
  security_group_ids = [aws_security_group.vpc_endpoint[0].id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  count             = var.create_vpc_endpoints == true ? 1 : 0
  vpc_id            = data.aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [data.aws_route_table.private.id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count              = var.create_vpc_endpoints == true ? 1 : 0
  vpc_id             = data.aws_vpc.this.id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [data.aws_subnet.private.id]
  security_group_ids = [aws_security_group.vpc_endpoint[0].id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api" {
  count              = var.create_vpc_endpoints == true ? 1 : 0
  vpc_id             = data.aws_vpc.this.id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [data.aws_subnet.private.id]
  security_group_ids = [aws_security_group.vpc_endpoint[0].id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "secrets_manager" {
  count              = local.secrets_manager == "AWSSecretsManager" && var.create_vpc_endpoints == true ? 1 : 0
  vpc_id             = data.aws_vpc.this.id
  service_name       = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [data.aws_subnet.private.id]
  security_group_ids = [aws_security_group.vpc_endpoint[0].id]

  private_dns_enabled = true
}

resource "aws_ecs_cluster" "datagrail_agent_cluster" {
  count = var.cluster_arn == "" ? 1 : 0
  name  = "${var.project_name}-cluster"
}

locals {
  cluster_id = var.cluster_arn == "" ? aws_ecs_cluster.datagrail_agent_cluster[0].id : var.cluster_arn
}

resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-service"
  cluster         = local.cluster_id
  task_definition = aws_ecs_task_definition.datagrail_agent.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_task_count

  network_configuration {
    subnets          = [data.aws_subnet.private.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.service_security_group.id]
  }
}
