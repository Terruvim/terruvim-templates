# Django ECS Container - Troubleshooting Guide

## ❌ Exit Code 3 - Common Causes and## 📋 ECS Task Definition Checklist

```json
{
  "environment": [
    {"name": "DEBUG", "value": "False"},
    {"name": "PORT", "value": "8080"},
    {"name": "SECRET_KEY", "value": "your-secret-key"},
    {"name": "DATABASE_URL", "value": "postgresql://user:pass@host:5432/db"},
    {"name": "ALLOWED_HOSTS", "value": "your-domain.com,*.your-domain.com"},
    {"name": "DJANGO_SETTINGS_MODULE", "value": "config.settings"}
  ],
  "healthCheck": {
    "command": ["CMD-SHELL", "curl -f http://localhost:8080/api/health/ || exit 1"],
    "interval": 30,
    "timeout": 10,
    "retries": 3,
    "startPeriod": 60
  }
}Database Connection Issues

**Most common cause**: Container can't connect to the database.

**Check:**
- Database endpoint is accessible from ECS tasks
- Security groups allow traffic on port 5432 (PostgreSQL)
- Database credentials are correct
- VPC/subnet configuration allows connectivity

**Required Environment Variables:**
```
DATABASE_URL=postgresql://username:password@host:5432/database_name
# OR
DB_HOST=your-rds-endpoint.amazonaws.com
DB_PORT=5432
DB_NAME=your_database
DB_USER=your_username
DB_PASSWORD=your_password
```

### 2. Missing Environment Variables

**Check ECS Task Definition includes:**
- `SECRET_KEY` - Django secret key
- `DATABASE_URL` or individual DB variables
- `ALLOWED_HOSTS` - Domain names/IPs allowed
- `DJANGO_SETTINGS_MODULE=config.settings`

### 3. Migration Failures

**Symptoms:** Container exits during `python manage.py migrate`

**Solutions:**
- Ensure database is created and accessible
- Check database user has proper permissions
- Verify migration files are included in Docker image

### 4. Permission Issues

**Check:**
- Container runs as `django` user (non-root)
- File permissions are correct
- Volume mounts have proper permissions

## 🔧 Debugging Steps

### 1. Check ECS Logs
```bash
# View container logs in CloudWatch
aws logs describe-log-streams --log-group-name "/ecs/your-task-definition"
aws logs get-log-events --log-group-name "/ecs/your-task-definition" --log-stream-name "ecs/container-name/task-id"
```

### 2. Test Locally
```bash
# Build and test locally
docker-compose up --build

# Or build and run individually
docker build -t django-app .
docker run --rm -e DATABASE_URL="postgresql://django:django@localhost:5432/django_db" django-app
```

### 3. Connect to Running Container (if it stays up)
```bash
# Get into container shell
docker exec -it container_id /bin/bash
# Or in ECS
aws ecs execute-command --cluster your-cluster --task your-task-id --container django --interactive --command "/bin/bash"
```

### 4. Test Database Connection
```bash
# Inside container
python manage.py dbshell
# Or test with psql
psql $DATABASE_URL
```

## 📋 ECS Task Definition Checklist

```json
{
  "environment": [
    {"name": "DEBUG", "value": "False"},
    {"name": "SECRET_KEY", "value": "your-secret-key"},
    {"name": "DATABASE_URL", "value": "postgresql://user:pass@host:5432/db"},
    {"name": "ALLOWED_HOSTS", "value": "your-domain.com,*.your-domain.com"},
    {"name": "DJANGO_SETTINGS_MODULE", "value": "config.settings"}
  ],
  "healthCheck": {
    "command": ["CMD-SHELL", "curl -f http://localhost:8000/api/health/ || exit 1"],
    "interval": 30,
    "timeout": 10,
    "retries": 3,
    "startPeriod": 60
  }
}
```

## 🚀 Quick Fix Commands

### Rebuild and Deploy
```bash
# Rebuild Docker image
docker build -t your-app:latest .

# Tag for ECR
docker tag your-app:latest your-account.dkr.ecr.region.amazonaws.com/your-repo:latest

# Push to ECR
docker push your-account.dkr.ecr.region.amazonaws.com/your-repo:latest

# Update ECS service
aws ecs update-service --cluster your-cluster --service your-service --force-new-deployment
```

### Force New Deployment
```bash
aws ecs update-service --cluster your-cluster --service your-service --force-new-deployment
```

## 📊 Monitoring

Set up CloudWatch alarms for:
- Container exit codes
- Health check failures
- Database connection errors
- High memory/CPU usage

## 💡 Best Practices

1. **Use health checks** - Helps ECS detect unhealthy containers
2. **Proper logging** - Set up structured logging for easier debugging
3. **Resource limits** - Set appropriate CPU/memory limits
4. **Secret management** - Use AWS Secrets Manager for sensitive data
5. **Database connection pooling** - Use connection pooling for better performance
