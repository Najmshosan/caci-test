# This Terraform script:

# Define the AWS provider
# Create an RDS instance with the specified configuration
# Outputs the RDS instance endpoint

# Terraform identifier
# Terraform validate
# terraform apply

# This will prompt to confirm the creation of resources that provision the RDS instance based on the specified configuration


provider "aws" {
  region = "your-aws-region"
}

resource "aws_db_instance" "rds_instance" {
  identifier           = "ecommerce-rds-instance"
  allocated_storage    = 100
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "ecommerce_database"
  username             = "db_user"
  password             = "your-strong-password"
  publicly_accessible  = false
  multi_az             = true
  backup_retention_period = 7
  skip_final_snapshot  = true
}

output "rds_endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}