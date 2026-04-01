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

# ─── Load Balancer Security Group ───
resource "aws_security_group" "load_balancer" {
  name        = "${var.vpc_name}-lb-sg"
  description = "Security group for the application load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-lb-sg"
  }
}

# ─── Application Security Group (updated — no direct internet access) ───
resource "aws_security_group" "application" {
  name        = "${var.vpc_name}-application-sg"
  description = "Security group for web application instances"
  vpc_id      = aws_vpc.main.id

  # SSH only
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # App port only from load balancer
  ingress {
    description     = "Application port from load balancer only"
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }

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

resource "aws_key_pair" "webapp" {
  key_name   = "${var.vpc_name}-webapp-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKkCneXFkO2saI54hlqkZlargBDmlQWjWu8Tx83LGTIU govindaraj.ke@northeastern.edu"
}

# ─── Launch Template ───
resource "aws_launch_template" "webapp" {
  name          = "csye6225_asg"
  image_id      = data.aws_ami.webapp.id
  instance_type = var.aws_instance_type
  key_name      = aws_key_pair.webapp.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.application.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.webapp_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_host        = aws_db_instance.webapp.address
    db_port        = tostring(aws_db_instance.webapp.port)
    db_name        = var.db_name
    db_username    = var.db_username
    db_password    = var.db_password
    s3_bucket_name = aws_s3_bucket.syllabus.bucket
    aws_region     = var.aws_region
    sns_topic_arn  = aws_sns_topic.user_verification.arn  
  }))

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 25
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.vpc_name}-webapp-asg-instance"
    }
  }
}

# ─── Target Group ───
resource "aws_lb_target_group" "webapp" {
  name     = "${var.vpc_name}-webapp-tg"
  port     = var.application_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    port                = tostring(var.application_port)
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name = "${var.vpc_name}-webapp-tg"
  }
}

# ─── Application Load Balancer ───
resource "aws_lb" "webapp" {
  name               = "${var.vpc_name}-webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = [for s in aws_subnet.public : s.id]

  tags = {
    Name = "${var.vpc_name}-webapp-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webapp.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }
}

# ─── Auto Scaling Group ───
resource "aws_autoscaling_group" "webapp" {
  name                      = "${var.vpc_name}-webapp-asg"
  min_size                  = 3
  max_size                  = 5
  desired_capacity          = 3
  default_cooldown          = 60
  vpc_zone_identifier       = [for s in aws_subnet.public : s.id]
  target_group_arns         = [aws_lb_target_group.webapp.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.webapp.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.vpc_name}-webapp-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AutoScalingGroup"
    value               = "csye6225_asg"
    propagate_at_launch = true
  }

  depends_on = [
    aws_lb_listener.http,
    aws_db_instance.webapp,
    aws_s3_bucket.syllabus,
    aws_iam_instance_profile.webapp_profile
  ]
}

# ─── Auto Scaling Policies ───
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.vpc_name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.webapp.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.vpc_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 5
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp.name
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.vpc_name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.webapp.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.vpc_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 3
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp.name
  }
}