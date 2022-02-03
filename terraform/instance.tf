# Retrieve all availability zones
data "aws_availability_zones" "azs" {
  state = "available"
}

# Retrieve all availability zones name
locals {
  az_names = data.aws_availability_zones.azs.names
}

# Create an amazon elastic container registry
resource "aws_ecr_repository" "iktos_test" {
  name = "iktos_test"
}

# Create a cluster
resource "aws_ecs_cluster" "iktos_cluster" {
  name = "iktos_cluster" # Naming the cluster
  
  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.key.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.application_log_group.name
      }
    }
  }
}

# Create a task for our container
resource "aws_ecs_task_definition" "iktos_task" {
  family                   = "iktos_task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "iktos_task",
      "image": "${aws_ecr_repository.iktos_test.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 5000
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "application_log_group",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "iktos"
        }
      },
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] 
  network_mode             = "awsvpc"   
  memory                   = 512       
  cpu                      = 256      
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}


#Create the role that will execute the task
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Providing a reference to our default subnets

resource "aws_default_subnet" "default_subnet" {
  for_each = toset(local.az_names)
  availability_zone = each.key
}

# Create a service linked to our cluster and our tasks
resource "aws_ecs_service" "iktos_service" {
  name            = "iktos_service"
  cluster         = aws_ecs_cluster.iktos_cluster.id
  task_definition = aws_ecs_task_definition.iktos_task.arn
  launch_type     = "FARGATE"
  desired_count   = 0

  #As the application is auto scaling, we don't want terraform to watch this change 
  # lifecycle {
  #   ignore_changes = [desired_count]
  # }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = aws_ecs_task_definition.iktos_task.family
    container_port   = 5000
  }

  network_configuration {
    subnets = [for az in local.az_names : aws_default_subnet.default_subnet[az].id]
    assign_public_ip = true
    security_groups  = [aws_security_group.service_security_group.id]
  }
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create the load balancer for our application
resource "aws_alb" "application_load_balancer" {
  name               = "iktos-lb"
  load_balancer_type = "application" 
  subnets = [for az in local.az_names : aws_default_subnet.default_subnet[az].id]
  security_groups = [aws_security_group.load_balancer_security_group.id]
}

# Creating a security group for the load balancer
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["176.185.234.248/32"] # Allow only my ip, but you can add yours if you want to access the application
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the target group 
resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn # Referencing our target group
  }
}
