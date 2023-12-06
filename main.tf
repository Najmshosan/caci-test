# This Terraform script:

# Define the AWS provider
# Create an RDS instance with the specified configuration
# Outputs the RDS instance endpoint

# Terraform identifier
# Terraform validate
# terraform apply

# This will prompt to confirm the creation of resources that provision the RDS instance based on the specified configuration


# provider "aws" {
#   region = "your-aws-region"
# }

# resource "aws_db_instance" "rds_instance" {
#   identifier           = "ecommerce-rds-instance"
#   allocated_storage    = 100
#   storage_type         = "gp2"
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t2.micro"
#   name                 = "ecommerce_database"
#   username             = "db_user"
#   password             = "your-strong-password"
#   publicly_accessible  = false
#   multi_az             = true
#   backup_retention_period = 7
#   skip_final_snapshot  = true
# }

# output "rds_endpoint" {
#   value = aws_db_instance.rds_instance.endpoint
# }

# main.tf

provider "aws" {
  region = "eu-west-1"  # region
}

# Create a VPC
resource "aws_vpc" "caci_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet
resource "aws_subnet" "caci_subnet" {
  vpc_id                  = aws_vpc.caci_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"  # availability zone
  map_public_ip_on_launch = true
}

# Create a security group for RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.caci_vpc.id
  
}

# Create RDS instance
resource "aws_db_instance" "caci_rds" {
  identifier           = "caci-rds-instance"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"  # database engine mysql
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "cacidatabase"
  username             = "admin_user"
  password             = "admin"  #  password
  multi_az             = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  subnet_group_name    = aws_db_subnet_group.caci_db_subnet_group.name
}

# Create a subnet group for RDS
resource "aws_db_subnet_group" "caci_db_subnet_group" {
  name       = "caci-db-subnet-group"
  subnet_ids = [aws_subnet.caci_subnet.id]
}

# ECS Cluster
resource "aws_ecs_cluster" "caci_ecs_cluster" {
  name = "caci-ecs-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "caci_ecs_task" {
  family                   = "caci-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "caci-container"
    image = "docker-image:latest"  # Docker image
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# ECS Service
resource "aws_ecs_service" "caci_ecs_service" {
  name            = "caci-ecs-service"
  cluster         = aws_ecs_cluster.caci_ecs_cluster.id
  task_definition = aws_ecs_task_definition.caci_ecs_task.arn
  launch_type     = "FARGATE"
  desired_count   = 2  
  network_configuration {
    subnets = [aws_subnet.caci_subnet.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Security Group for ECS
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.caci_vpc.id
  description = "Security group for ECS"
}
