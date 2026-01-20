#!/bin/bash
# Emergency troubleshooting script for ECS exit code 3

echo "🚨 Django ECS Exit Code 3 - Emergency Diagnostics"
echo "=================================================="

# Check if we're in ECS environment
if [ -n "$AWS_EXECUTION_ENV" ]; then
    echo "📍 Running in ECS environment"
    echo "Task ARN: $AWS_EXECUTION_ENV"
else
    echo "📍 Running locally"
fi

echo ""
echo "🔍 Environment Variables Check:"
echo "------------------------------"
echo "DEBUG: ${DEBUG:-not set}"
echo "SECRET_KEY: ${SECRET_KEY:+***set***}"
echo "DATABASE_URL: ${DATABASE_URL:+***set***}"
echo "DB_HOST: ${DB_HOST:-not set}"
echo "DB_PORT: ${DB_PORT:-not set}"
echo "DB_NAME: ${DB_NAME:-not set}"
echo "DB_USER: ${DB_USER:+***set***}"
echo "DB_PASSWORD: ${DB_PASSWORD:+***set***}"
echo "ALLOWED_HOSTS: ${ALLOWED_HOSTS:-not set}"
echo "DJANGO_SETTINGS_MODULE: ${DJANGO_SETTINGS_MODULE:-not set}"
echo "PORT: ${PORT:-not set}"

echo ""
echo "🔍 Required Variables Analysis:"
echo "------------------------------"
MISSING_VARS=()

if [ -z "$SECRET_KEY" ]; then
    MISSING_VARS+=("SECRET_KEY")
fi

if [ -z "$DATABASE_URL" ] && [ -z "$DB_HOST" ]; then
    MISSING_VARS+=("DATABASE_URL or DB_HOST")
fi

if [ -z "$ALLOWED_HOSTS" ]; then
    MISSING_VARS+=("ALLOWED_HOSTS")
fi

if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    echo "✅ All required variables are set"
else
    echo "❌ Missing required variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
fi

echo ""
echo "🔍 Database Connection Test:"
echo "---------------------------"

# Determine database host and port
if [ -n "$DATABASE_URL" ]; then
    DB_HOST_TEST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\).*/\1/p')
    DB_PORT_TEST=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    echo "Extracted from DATABASE_URL: $DB_HOST_TEST:$DB_PORT_TEST"
else
    DB_HOST_TEST=${DB_HOST}
    DB_PORT_TEST=${DB_PORT:-5432}
    echo "Using individual variables: $DB_HOST_TEST:$DB_PORT_TEST"
fi

if [ -n "$DB_HOST_TEST" ]; then
    echo "Testing connection to $DB_HOST_TEST:$DB_PORT_TEST"
    
    if command -v nc >/dev/null 2>&1; then
        if nc -z "$DB_HOST_TEST" "$DB_PORT_TEST" 2>/dev/null; then
            echo "✅ Database port is reachable"
        else
            echo "❌ Cannot connect to database at $DB_HOST_TEST:$DB_PORT_TEST"
            echo "This is likely the cause of exit code 3"
        fi
    else
        echo "⚠️  netcat not available, cannot test database connection"
    fi
else
    echo "❌ No database host specified"
fi

echo ""
echo "🔍 Django Configuration Test:"
echo "----------------------------"

# Test Django settings
if [ -n "$DJANGO_SETTINGS_MODULE" ]; then
    echo "Testing Django settings: $DJANGO_SETTINGS_MODULE"
    if python -c "import django; django.setup()" 2>/dev/null; then
        echo "✅ Django settings load successfully"
    else
        echo "❌ Django settings failed to load"
        echo "Error details:"
        python -c "import django; django.setup()" 2>&1 || true
    fi
else
    echo "❌ DJANGO_SETTINGS_MODULE not set"
fi

echo ""
echo "🔍 File System Check:"
echo "--------------------"
echo "Current directory: $(pwd)"
echo "Django files present:"
if [ -f "manage.py" ]; then
    echo "✅ manage.py found"
else
    echo "❌ manage.py not found"
fi

if [ -d "config" ]; then
    echo "✅ config directory found"
else
    echo "❌ config directory not found"
fi

echo ""
echo "🔍 Port Configuration:"
echo "--------------------"
echo "Port setting: ${PORT:-8080}"
if netstat -ln | grep ":${PORT:-8080}" >/dev/null 2>&1; then
    echo "⚠️  Port ${PORT:-8080} already in use"
else
    echo "✅ Port ${PORT:-8080} is available"
fi

echo ""
echo "🔍 Process and Memory:"
echo "--------------------"
echo "Available memory:"
free -h 2>/dev/null || echo "free command not available"
echo "Running processes:"
ps aux | head -5 2>/dev/null || echo "ps command not available"

echo ""
echo "🔍 Python Environment:"
echo "--------------------"
echo "Python version: $(python --version 2>&1)"
echo "Python path: $(which python)"
echo "Django version:"
python -c "import django; print(f'Django {django.VERSION}')" 2>/dev/null || echo "Django import failed"

echo ""
echo "💡 Quick Fix Suggestions:"
echo "========================"
echo "1. If database connection failed:"
echo "   - Check security groups allow port 5432"
echo "   - Verify Aurora cluster is in 'available' state"
echo "   - Check VPC/subnet connectivity"
echo ""
echo "2. If environment variables missing:"
echo "   - Update ECS task definition"
echo "   - Check AWS Secrets Manager configuration"
echo ""
echo "3. If Django settings failed:"
echo "   - Verify DJANGO_SETTINGS_MODULE points to existing file"
echo "   - Check SECRET_KEY is properly set"
echo ""
echo "🔧 To view ECS logs:"
echo "aws logs tail /ecs/project42-django --follow"
echo ""
echo "🔧 To check ECS task details:"
echo "aws ecs describe-tasks --cluster project42-cluster --tasks <task-id>"
