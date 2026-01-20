#!/bin/bash
# Django entrypoint script for ECS/Docker with enhanced debugging

set -e

echo "🚀 Starting Django application..."
echo "================================="
echo "Timestamp: $(date)"
echo "Container ID: ${HOSTNAME}"
echo "Working directory: $(pwd)"

# Enhanced environment check
echo ""
echo "🔍 Environment Variables Check:"
echo "------------------------------"
echo "DEBUG: ${DEBUG:-not set}"
echo "SECRET_KEY: ${SECRET_KEY:+***set*** (${#SECRET_KEY} chars)}"
echo "DATABASE_URL: ${DATABASE_URL:+***set*** (${#DATABASE_URL} chars)}"
if [ -n "$DATABASE_URL" ]; then
    echo "DATABASE_URL preview: $(echo $DATABASE_URL | sed 's/:[^@]*@/:***@/')"
fi
echo "DB_HOST: ${DB_HOST:-not set}"
echo "DB_PORT: ${DB_PORT:-not set}"
echo "DB_NAME: ${DB_NAME:-not set}"
echo "DB_USER: ${DB_USER:+***set***}"
echo "DB_PASSWORD: ${DB_PASSWORD:+***set***}"
echo "ALLOWED_HOSTS: ${ALLOWED_HOSTS:-not set}"
echo "DJANGO_SETTINGS_MODULE: ${DJANGO_SETTINGS_MODULE:-not set}"
echo "PORT: ${PORT:-8080}"

# Print all environment variables containing DB or DJANGO
echo ""
echo "🔍 All DB/DJANGO related environment variables:"
echo "----------------------------------------------"
env | grep -E "(DATABASE|DB_|DJANGO)" | sort

# Check required environment variables
echo ""
echo "🔍 Validating Required Variables:"
echo "--------------------------------"
VALIDATION_FAILED=false

if [ -z "$SECRET_KEY" ]; then
    echo "❌ ERROR: SECRET_KEY environment variable is required"
    VALIDATION_FAILED=true
else
    echo "✅ SECRET_KEY is set"
fi

if [ -z "$DATABASE_URL" ] && [ -z "$DB_HOST" ]; then
    echo "❌ ERROR: DATABASE_URL or DB_HOST must be set"
    VALIDATION_FAILED=true
else
    echo "✅ Database configuration found"
fi

if [ -z "$ALLOWED_HOSTS" ]; then
    echo "❌ ERROR: ALLOWED_HOSTS must be set"
    VALIDATION_FAILED=true
else
    echo "✅ ALLOWED_HOSTS is set: $ALLOWED_HOSTS"
fi

if [ "$VALIDATION_FAILED" = true ]; then
    echo ""
    echo "❌ FATAL: Required environment variables are missing"
    echo "Please check your ECS task definition or docker-compose configuration"
    exit 3
fi

# Wait for database to be ready
echo ""
echo "⏳ Database Connection Test:"
echo "---------------------------"

# Check if SQLite (file-based database)
if [[ "$DATABASE_URL" =~ ^sqlite:// ]]; then
    echo "✅ SQLite database detected - no connection test needed"
    echo "Database file: ${DATABASE_URL#sqlite://}"
else
    # PostgreSQL or other network database
    DB_HOST_VAR=${DB_HOST:-$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\).*/\1/p' 2>/dev/null)}
    DB_PORT_VAR=${DB_PORT:-5432}

    if [ -z "$DB_HOST_VAR" ]; then
        echo "❌ ERROR: Cannot determine database host"
        echo "DATABASE_URL format should be: postgresql://user:pass@host:port/db"
        echo "Current DATABASE_URL: $DATABASE_URL"
        exit 3
    fi

    echo "Testing connection to: $DB_HOST_VAR:$DB_PORT_VAR"

    # More robust database wait with timeout and better error messages
    TIMEOUT=60
    COUNTER=0
    until nc -z "$DB_HOST_VAR" "$DB_PORT_VAR" || [ $COUNTER -ge $TIMEOUT ]; do
        if [ $COUNTER -eq 0 ]; then
            echo "Waiting for database to become available..."
        elif [ $((COUNTER % 10)) -eq 0 ]; then
            echo "Still waiting for database... ($COUNTER/${TIMEOUT}s)"
            echo "Checking if host is resolvable:"
            nslookup "$DB_HOST_VAR" || echo "DNS resolution failed for $DB_HOST_VAR"
        fi
        sleep 2
        COUNTER=$((COUNTER + 2))
    done

    if [ $COUNTER -ge $TIMEOUT ]; then
        echo ""
        echo "❌ FATAL: Database connection timeout after ${TIMEOUT}s"
        echo "Failed to connect to: $DB_HOST_VAR:$DB_PORT_VAR"
        echo ""
        echo "Possible causes:"
        echo "1. Database server is not running"
        echo "2. Security groups don't allow connection on port $DB_PORT_VAR"
        echo "3. Network connectivity issues between ECS and RDS"
        echo "4. Incorrect database endpoint"
        echo ""
        echo "Debug commands:"
        echo "- Check RDS status: aws rds describe-db-clusters"
        echo "- Check security groups: aws ec2 describe-security-groups"
        echo "- Test from ECS subnet: aws ecs execute-command --cluster <cluster> --task <task> --interactive --command '/bin/bash'"
        exit 3
    fi

    echo "✅ Database connection successful!"
fi

# Django setup and validation
echo ""
echo "🐍 Django Configuration Test:"
echo "----------------------------"
echo "Settings module: ${DJANGO_SETTINGS_MODULE:-config.settings}"

# Test Django settings import
if ! python -c "
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', '${DJANGO_SETTINGS_MODULE:-config.settings}')
import django
django.setup()
print('✅ Django settings loaded successfully')
" 2>/dev/null; then
    echo "❌ FATAL: Django settings failed to load"
    echo "Testing settings import with error details:"
    python -c "
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', '${DJANGO_SETTINGS_MODULE:-config.settings}')
import django
django.setup()
" 2>&1 || echo "Django setup failed"
    exit 3
fi

# Run migrations
echo ""
echo "📦 Database Migrations:"
echo "---------------------"
if ! python manage.py migrate --noinput; then
    echo "❌ FATAL: Database migration failed"
    echo "This could be due to:"
    echo "1. Database user lacks sufficient permissions"
    echo "2. Database connection parameters are incorrect"
    echo "3. Database is not properly initialized"
    echo "4. Migration conflicts"
    echo ""
    echo "Try running: python manage.py showmigrations"
    exit 3
fi

# Collect static files
echo ""
echo "📁 Static Files Collection:"
echo "--------------------------"
if ! python manage.py collectstatic --noinput; then
    echo "⚠️  WARNING: Static files collection failed, but continuing..."
    echo "This is not critical for API-only applications"
fi

# Create superuser if not exists (optional, for dev)
if [ "$DJANGO_SUPERUSER_EMAIL" ]; then
    echo ""
    echo "👤 Creating Superuser:"
    echo "--------------------"
    python manage.py ensure_superuser
fi

echo ""
echo "✅ Django initialization complete!"
echo "================================="
echo "Starting application on port ${PORT:-8080}"
echo "Health check available at: http://localhost:${PORT:-8080}/api/health/"
echo ""

# Start the application
exec "$@"
