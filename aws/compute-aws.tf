# Data source to get the latest custom AMI
data "aws_ami" "webapp" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["webapp-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Application Security Group
resource "aws_security_group" "application" {
  name        = "${var.vpc_name}-application-sg"
  description = "Security group for web application instances"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application port
  ingress {
    description = "Application port from anywhere"
    from_port   = var.application_port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound - allow all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-application-sg"
  }
}

# EC2 Instance
resource "aws_instance" "webapp" {
  ami           = data.aws_ami.webapp.id
  instance_type = var.aws_instance_type
  
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.application.id]

  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  disable_api_termination = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  tags = {
    Name = "${var.vpc_name}-webapp-instance"
  }

  depends_on = [
    aws_subnet.public,
    aws_internet_gateway.main,
    aws_route_table.public
  ]
}