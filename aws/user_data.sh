#!/bin/bash
set -e

echo "=== EC2 User Data: Configuring webapp ==="

# Write environment file for the webapp service
cat > /opt/webapp/.env <<ENVEOF
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
S3_BUCKET_NAME=${s3_bucket_name}
AWS_REGION=${aws_region}
APP_HOST=0.0.0.0
APP_PORT=8080
ENVEOF

# Set proper ownership and permissions
chown csye6225:csye6225 /opt/webapp/.env
chmod 600 /opt/webapp/.env

# Install dependencies (in case not baked into AMI)
if [ -f /opt/webapp/requirements.txt ]; then
    /opt/webapp/venv/bin/pip install -r /opt/webapp/requirements.txt
fi

# Reload systemd and start the webapp
systemctl daemon-reload
systemctl enable webapp.service
systemctl restart webapp.service

echo "=== Configuring CloudWatch Agent ==="

# Configure and start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json \
  -s

systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent

echo "=== EC2 User Data: Configuration complete ==="
