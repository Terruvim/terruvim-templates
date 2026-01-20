#!/bin/bash
# Quick deployment and testing script

set -e

echo "🚀 Django ECS Deployment Script"
echo "==============================="

# Configuration
REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${ECS_CLUSTER:-project42-cluster}
SERVICE_NAME=${ECS_SERVICE:-project42-django}
ECR_REPO=${ECR_REPOSITORY:-project42/django}

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Build image
echo "🏗️  Building Docker image..."
docker build -t django-app .

# Tag for ECR
echo "🏷️  Tagging image for ECR..."
docker tag django-app:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest

# Login to ECR
echo "🔑 Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Push to ECR
echo "⬆️  Pushing image to ECR..."
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest

# Update ECS service
echo "🔄 Updating ECS service..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment --region $REGION

# Wait for deployment to complete
echo "⏳ Waiting for deployment to complete..."
aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION

echo "✅ Deployment complete!"

# Get service status
echo ""
echo "📊 Service Status:"
aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].{Status:status,RunningCount:runningCount,PendingCount:pendingCount,DesiredCount:desiredCount}'

# Get recent logs
echo ""
echo "📋 Recent Logs (last 10 minutes):"
LOG_GROUP="/ecs/$SERVICE_NAME"
STREAM_NAME=$(aws logs describe-log-streams --log-group-name $LOG_GROUP --order-by LastEventTime --descending --limit 1 --query 'logStreams[0].logStreamName' --output text --region $REGION 2>/dev/null || echo "")

if [ -n "$STREAM_NAME" ] && [ "$STREAM_NAME" != "None" ]; then
    aws logs get-log-events --log-group-name $LOG_GROUP --log-stream-name $STREAM_NAME --start-time $(($(date +%s)*1000 - 600000)) --region $REGION --query 'events[*].message' --output text
else
    echo "No recent logs found"
fi
