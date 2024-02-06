terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.21.0"
    }
  }

  required_version = ">= 1.5.0"
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnet" "public" {
  for_each = var.public_subnet_ids

  id = each.value
}

data "aws_subnet" "private" {
  id = var.private_subnet_id
}

data "aws_route_table" "private" {
  subnet_id = var.private_subnet_id
}

data "aws_route53_zone" "selected" {
  name         = var.hosted_zone_name
  private_zone = false
}

data "aws_prefix_list" "s3" {
  prefix_list_id = aws_vpc_endpoint.s3[0].prefix_list_id
}

locals {
  raw_config      = jsondecode(file("config/datagrail-agent-config.json"))
  secrets_manager = local.raw_config.platform.credentials_manager.provider
  bucket_name     = local.raw_config.platform.storage_manager.options.bucket
  credentials = concat([local.raw_config.datagrail_agent_credentials_location],
    [local.raw_config.datagrail_credentials_location],
  [for connection in local.raw_config.connections : connection.credentials_location])
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
    sid = "S3PutObject"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }

  statement {
    sid = "SecretsManagerGetSecretValue"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = local.credentials

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
        "/etc/rm.conf"
      ],
      environment = [
        { "name" = "DATAGRAIL_AGENT_CONFIG", "value" = file("config/datagrail-agent-config.json") }
      ]
      cpu              = 0
      workingDirectory = "/app"
      image            = var.agent_image_uri
      healthCheck = {
        "retries" = 3
        "command" = [
          "CMD-SHELL",
          "curl -f http://localhost/docs || exit 1"
        ],
        "timeout"     = 5
        "interval"    = 30
        "startPeriod" = 1
      },
      essential = true
    }
  ])
}

resource "aws_security_group" "load_balancer_security_group" {
  name   = "${var.project_name}-load-balancer-security-group"
  vpc_id = data.aws_vpc.this.id
}

resource "aws_security_group_rule" "load_balancer_ingress_rule" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.load_balancer_security_group.id
  cidr_blocks       = concat(["52.36.177.91/32"], var.load_balancer_ingress_cidr)
}

resource "aws_security_group_rule" "load_balancer_egress_rule" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.load_balancer_security_group.id
  source_security_group_id = aws_security_group.service_security_group.id
}

resource "aws_security_group" "service_security_group" {
  name   = "${var.project_name}-service-security-group"
  vpc_id = data.aws_vpc.this.id
}

resource "aws_security_group_rule" "service_ingress_rule" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.service_security_group.id
  source_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_security_group_rule" "service_egress_datagrail_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.service_security_group.id
  cidr_blocks       = ["52.36.177.91/32"]
}

resource "aws_security_group_rule" "service_egress_additional_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.service_security_group.id
  cidr_blocks       = var.service_egress_cidr
}

resource "aws_security_group_rule" "service_egress_private_s3_rule" {
  count             = var.create_vpc_endpoints == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.service_security_group.id
  cidr_blocks       = data.aws_prefix_list.s3.cidr_blocks
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

resource "aws_vpc_endpoint" "s3" {
  count             = var.create_vpc_endpoints == true ? 1 : 0
  vpc_id            = data.aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [data.aws_route_table.private.id]
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

resource "aws_alb_target_group" "datagrail_agent" {
  name        = "${var.project_name}-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.this.id
  health_check {
    path = "/docs"
  }
}

resource "aws_alb" "application_load_balancer" {
  name               = "${var.project_name}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  subnets            = values(data.aws_subnet.public)[*].id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.load_balancer_ssl_policy
  certificate_arn   = var.tls_certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.datagrail_agent.arn
  }
}

resource "aws_ecs_cluster" "datagrail_agent_cluster" {
  count = var.cluster_id == "" ? 1 : 0
  name  = "${var.project_name}-cluster"
}

locals {
  cluster_id = var.cluster_id == "" ? aws_ecs_cluster.datagrail_agent_cluster[0].id : var.cluster_id
}

resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-service"
  cluster         = local.cluster_id
  task_definition = aws_ecs_task_definition.datagrail_agent.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_task_count

  load_balancer {
    target_group_arn = aws_alb_target_group.datagrail_agent.arn
    container_name   = aws_ecs_task_definition.datagrail_agent.family
    container_port   = 80
  }

  network_configuration {
    subnets          = [data.aws_subnet.private.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.service_security_group.id]
  }
}

resource "aws_route53_record" "datagrail_agent_alb_alias" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.agent_subdomain}.${data.aws_route53_zone.selected.name}"
  type    = "A"

  alias {
    name                   = aws_alb.application_load_balancer.dns_name
    zone_id                = aws_alb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}