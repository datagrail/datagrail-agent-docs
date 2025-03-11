terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.21.0"
    }
  }
  required_version = ">= 1.5.0"
}


################################################################################
# Task Execution - IAM Role
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
################################################################################

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

################################################################################
# Tasks - IAM role
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
################################################################################

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

    resources = [aws_secretsmanager_secret.api_key.arn]

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

################################################################################
# CloudWatch
################################################################################

resource "aws_cloudwatch_log_group" "ecs_task_logger" {
  name = "/aws/ecs/${var.project_name}"

  retention_in_days = var.cloudwatch_log_retention
}

################################################################################
# Task Definition
################################################################################

locals {
  datagrail_agent_config = jsonencode({
    "customer_domain" : var.datagrail_subdomain,
    "datagrail_credentials_location" : aws_secretsmanager_secret.api_key.arn,
    "platform" : {
      "credentials_manager" : {
        "provider" : var.credentials_manager
      }
    }
  })
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
          "awslogs-stream-prefix" = "ecs"
        }
      },
      command = [
        "supervisord",
        "-n",
        "-c",
        "/etc/rdd.conf"
      ],
      environment = [
        { "name" = "DATAGRAIL_AGENT_CONFIG", "value" = local.datagrail_agent_config }
      ]
      cpu              = 0
      workingDirectory = "/app"
      image            = var.agent_image_uri
      healthCheck = {
        "retries" = 3
        "command" = [
          "CMD-SHELL",
          "test -f /app/healthy"
        ],
        "timeout"     = 5
        "interval"    = 30
        "startPeriod" = 1
      },
      essential = true
    }
  ])
}

################################################################################
# Cluster
################################################################################

resource "aws_ecs_cluster" "datagrail_agent" {
  count = var.cluster_arn == "" ? 1 : 0
  name  = "${var.project_name}-cluster"
}

################################################################################
# Service
################################################################################

resource "aws_security_group" "service" {
  name        = "${var.project_name}-service-security-group"
  vpc_id      = var.vpc_id
  description = "Security group attached to the ${var.project_name} service."
}

resource "aws_vpc_security_group_egress_rule" "service_to_anywhere" {
  security_group_id = aws_security_group.service.id

  description = "Allow datagrail-rdd-agent service egress to anywhere"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-service"
  cluster         = try(aws_ecs_cluster.datagrail_agent[0].arn, var.cluster_arn)
  task_definition = aws_ecs_task_definition.datagrail_agent.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_task_count

  network_configuration {
    subnets          = var.private_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.service.id]
  }
}

resource "aws_secretsmanager_secret" "api_key" {
  name                    = "datagrail.rdd_agent_api_key"
  description             = "API token used to authenticate requests to DataGrail."
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id = aws_secretsmanager_secret.api_key.id
  secret_string = jsonencode({
    "token" : var.datagrail_credentials
  })
}