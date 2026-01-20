#!/bin/bash
# Script to check ECS logs and diagnose exit code 3

set -e

echo "🔍 ECS Django Container Diagnostics"
echo "=================================="

# Configuration
CLUSTER_NAME=${ECS_CLUSTER:-project42-cluster}
SERVICE_NAME=${ECS_SERVICE:-project42-django}
REGION=${AWS_REGION:-us-east-1}

echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
echo "Region: $REGION"

# Check service status
echo ""
echo "📊 ECS Service Status:"
echo "--------------------"
aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --region "$REGION" \
  --query 'services[0].{
    Status: status,
    Running: runningCount,
    Pending: pendingCount,
    Desired: desiredCount,
    TaskDefinition: taskDefinition
  }' \
  --output table

# Get recent tasks
echo ""
echo "📋 Recent Tasks:"
echo "---------------"
TASK_ARNS=$(aws ecs list-tasks \
  --cluster "$CLUSTER_NAME" \
  --service-name "$SERVICE_NAME" \
  --region "$REGION" \
  --query 'taskArns' \
  --output text)

if [ -n "$TASK_ARNS" ]; then
    echo "Found tasks: $TASK_ARNS"
    
    # Get task details
    aws ecs describe-tasks \
      --cluster "$CLUSTER_NAME" \
      --tasks $TASK_ARNS \
      --region "$REGION" \
      --query 'tasks[*].{
        TaskArn: taskArn,
        LastStatus: lastStatus,
        DesiredStatus: desiredStatus,
        HealthStatus: healthStatus,
        CreatedAt: createdAt,
        StoppedAt: stoppedAt,
        StopCode: stopCode,
        StoppedReason: stoppedReason
      }' \
      --output table
      
    # Get latest task for logs
    LATEST_TASK=$(echo $TASK_ARNS | tr ' ' '\n' | tail -1)
    TASK_ID=$(echo $LATEST_TASK | sed 's/.*\///')
    
    echo ""
    echo "🔍 Container Status for latest task:"
    echo "-----------------------------------"
    aws ecs describe-tasks \
      --cluster "$CLUSTER_NAME" \
      --tasks "$LATEST_TASK" \
      --region "$REGION" \
      --query 'tasks[0].containers[*].{
        Name: name,
        LastStatus: lastStatus,
        ExitCode: exitCode,
        Reason: reason
      }' \
      --output table
else
    echo "No tasks found for service $SERVICE_NAME"
fi

# Check CloudWatch logs
echo ""
echo "📜 CloudWatch Logs:"
echo "-----------------"
LOG_GROUP="/ecs/$SERVICE_NAME"

# Check if log group exists
if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$REGION" --query 'logGroups[0]' --output text | grep -q "$LOG_GROUP"; then
    echo "Log group found: $LOG_GROUP"
    
    # Get recent log streams
    echo ""
    echo "Recent log streams:"
    aws logs describe-log-streams \
      --log-group-name "$LOG_GROUP" \
      --order-by LastEventTime \
      --descending \
      --limit 3 \
      --region "$REGION" \
      --query 'logStreams[*].{
        Name: logStreamName,
        LastEvent: lastEventTime,
        Size: storedBytes
      }' \
      --output table
    
    # Get latest logs
    LATEST_STREAM=$(aws logs describe-log-streams \
      --log-group-name "$LOG_GROUP" \
      --order-by LastEventTime \
      --descending \
      --limit 1 \
      --region "$REGION" \
      --query 'logStreams[0].logStreamName' \
      --output text)
    
    if [ "$LATEST_STREAM" != "None" ] && [ -n "$LATEST_STREAM" ]; then
        echo ""
        echo "🔍 Latest logs from: $LATEST_STREAM"
        echo "=================================="
        aws logs get-log-events \
          --log-group-name "$LOG_GROUP" \
          --log-stream-name "$LATEST_STREAM" \
          --start-time $(($(date +%s)*1000 - 3600000)) \
          --region "$REGION" \
          --query 'events[*].message' \
          --output text
    else
        echo "No recent log streams found"
    fi
else
    echo "❌ Log group not found: $LOG_GROUP"
    echo "Available log groups:"
    aws logs describe-log-groups --region "$REGION" --query 'logGroups[*].logGroupName' --output text
fi

# Check Aurora cluster status
echo ""
echo "🔍 Aurora Cluster Status:"
echo "------------------------"
CLUSTER_IDENTIFIER=$(aws rds describe-db-clusters \
  --region "$REGION" \
  --query 'DBClusters[?contains(DBClusterIdentifier, `project42`) || contains(DBClusterIdentifier, `aurora`)].{
    Identifier: DBClusterIdentifier,
    Status: Status,
    Endpoint: Endpoint,
    Port: Port,
    Engine: Engine
  }' \
  --output table)

if [ -n "$CLUSTER_IDENTIFIER" ]; then
    echo "$CLUSTER_IDENTIFIER"
else
    echo "No Aurora clusters found with 'project42' or 'aurora' in name"
    echo "All RDS clusters:"
    aws rds describe-db-clusters --region "$REGION" --query 'DBClusters[*].DBClusterIdentifier' --output text
fi

# Check security groups
echo ""
echo "🔍 Security Groups Check:"
echo "------------------------"
# Get VPC ID first
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=project42" \
  --region "$REGION" \
  --query 'Vpcs[0].VpcId' \
  --output text 2>/dev/null || echo "")

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    echo "Project VPC: $VPC_ID"
    echo ""
    echo "Security groups in project VPC:"
    aws ec2 describe-security-groups \
      --filters "Name=vpc-id,Values=$VPC_ID" \
      --region "$REGION" \
      --query 'SecurityGroups[*].{
        GroupId: GroupId,
        GroupName: GroupName,
        Description: Description
      }' \
      --output table
else
    echo "Could not find project VPC"
fi

echo ""
echo "💡 Common Exit Code 3 Causes:"
echo "============================"
echo "1. Database connection timeout"
echo "   - Check Aurora cluster status"
echo "   - Verify security groups allow port 5432"
echo "   - Check VPC/subnet routing"
echo ""
echo "2. Missing environment variables"
echo "   - SECRET_KEY, DATABASE_URL, ALLOWED_HOSTS"
echo "   - Check AWS Secrets Manager integration"
echo ""
echo "3. Django configuration errors"
echo "   - Invalid settings module"
echo "   - Database migration failures"
echo ""
echo "4. Resource constraints"
echo "   - Insufficient memory/CPU"
echo "   - Container startup timeout"
echo ""
echo "🔧 Next steps:"
echo "============="
echo "1. Check logs above for specific error messages"
echo "2. Test database connectivity from ECS subnet"
echo "3. Verify task definition environment variables"
echo "4. Run emergency_debug.sh inside container"
