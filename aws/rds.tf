# ─── Database Security Group ───

resource "aws_security_group" "database" {
  name        = "${var.vpc_name}-database-sg"
  description = "Security group for RDS instances - only allows traffic from application SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from application SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-database-sg"
  }
}

# ─── DB Subnet Group (private subnets only) ───

resource "aws_db_subnet_group" "private" {
  name       = "${var.vpc_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.vpc_name}-db-subnet-group"
  }
}

# ─── RDS Parameter Group ───

resource "aws_db_parameter_group" "webapp" {
  name   = "${var.vpc_name}-db-params"
  family = var.db_parameter_group_family

  tags = {
    Name = "${var.vpc_name}-db-parameter-group"
  }
}

# ─── RDS Instance ───

resource "aws_db_instance" "webapp" {
  identifier     = "csye6225"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result  # ← now auto-generated

  # KMS encryption for RDS
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_key.arn

  db_subnet_group_name   = aws_db_subnet_group.private.name
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.database.id]

  parameter_group_name = aws_db_parameter_group.webapp.name

  multi_az                  = false
  skip_final_snapshot       = true
  final_snapshot_identifier = "csye6225-final-snapshot"
  backup_retention_period   = 0

  tags = {
    Name = "${var.vpc_name}-rds-instance"
  }

  depends_on = [
    aws_db_subnet_group.private,
    aws_security_group.database,
    aws_kms_key.rds_key
  ]
}