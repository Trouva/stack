/**
 * The task module creates an ECS task definition.
 *
 * Usage:
 *
 *     module "nginx" {
 *       source = "github.com/segmentio/stack/task"
 *       name   = "nginx"
 *       image  = "nginx"
 *     }
 *
 */

/**
 * Required Variables.
 */

variable "image" {
  description = "The docker image name, e.g nginx"
}

variable "name" {
  description = "The worker name, if empty the service name is defaulted to the image name"
}

/**
 * Optional Variables.
 */

variable "cpu" {
  description = "The number of cpu units to reserve for the container"
  default     = 512
}

variable "env_vars" {
  description = "The raw json of the task env vars"
  default     = "[]"
} # [{ "name": name, "value": value }]

variable "command" {
  description = "The raw json of the task command"
  default     = "[]"
} # ["--key=foo","--port=bar"]

variable "entry_point" {
  description = "The docker container entry point"
  default     = "[]"
}

variable "ports" {
  description = "The docker container ports"
  default     = "[]"
}

variable "image_version" {
  description = "The docker image version"
  default     = "latest"
}

variable "memory" {
  description = "The number of MiB of memory to reserve for the container"
  default     = 512
}

variable "launch_type" {
  default = "EC2"
}

variable "task_role_arn" {
  default = ""
}

variable "task_execution_role_arn" {
  default = ""
}

variable "region" {
  description = "The region for this task"
  default     = "eu-west-1"
}

/**
 * Resources.
 */

# The ECS task definition.

resource "aws_ecs_task_definition" "main" {
  family = "${var.name}"

  memory = "${var.memory}"
  cpu    = "${var.cpu}"

  requires_compatibilities = [ "${var.launch_type == "FARGATE" ? "FARGATE" : "EC2" }" ]
  network_mode             = "${var.launch_type == "FARGATE" ? "awsvpc" : ""}"
  execution_role_arn       = "${var.task_role_arn}"

  lifecycle {
    ignore_changes        = ["image"]
    create_before_destroy = true
  }

  container_definitions = <<EOF
[
  {
    "cpu": ${var.cpu},
    "environment": ${var.env_vars},
    "essential": true,
    "command": ${var.command},
    "image": "${var.image}:${var.image_version}",
    "memory": ${var.memory},
    "name": "${var.name}",
    "portMappings": ${var.ports},
    "entryPoint": ${var.entry_point},
    "mountPoints": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${var.name}",
        ${var.launch_type == "FARGATE" ? "\"awslogs-stream-prefix\": \"service\"," : ""}
        "awslogs-region": "${var.region}"
      }
    }
  }
]
EOF
}

/**
 * Outputs.
 */

// The created task definition name
output "name" {
  value = "${aws_ecs_task_definition.main.family}"
}

// The created task definition ARN
output "arn" {
  value = "${aws_ecs_task_definition.main.arn}"
}
