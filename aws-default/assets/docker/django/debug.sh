#!/bin/bash
# Django ECS Debugging Script

set -e

echo "🔍 Django ECS Container Debugging Script"
echo "========================================"

# Check if running in container
if [ -f /.dockerenv ]; then
    echo "✅ Running inside Docker container"
else
    echo "❌ Not running in Docker container"
fi

# Check environment variables
echo ""
echo "📋 Environment Variables Check:"
echo "------------------------------"

check_env() {
    if [ -n "${!1}" ]; then
        echo "✅ $1 = ${!1}"
    else
        echo "❌ $1 is not set"
    fi
}

check_env "DATABASE_URL"
check_env "DB_HOST"
check_env "DB_PORT"
check_env "SECRET_KEY"
check_env "DJANGO_SETTINGS_MODULE"
check_env "ALLOWED_HOSTS"

# Test database connection
echo ""
echo "🗄️  Database Connection Test:"
echo "-----------------------------"

if [ -n "$DATABASE_URL" ]; then
    DB_HOST_VAR=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\).*/\1/p')
    DB_PORT_VAR=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
elif [ -n "$DB_HOST" ]; then
    DB_HOST_VAR=$DB_HOST
    DB_PORT_VAR=${DB_PORT:-5432}
else
    echo "❌ No database configuration found"
    exit 1
fi

echo "Testing connection to $DB_HOST_VAR:$DB_PORT_VAR"

if command -v nc >/dev/null 2>&1; then
    if nc -z "$DB_HOST_VAR" "$DB_PORT_VAR"; then
        echo "✅ Database is reachable"
    else
        echo "❌ Database is NOT reachable"
    fi
else
    echo "⚠️  netcat not available, cannot test connection"
fi

# Test Django
echo ""
echo "🐍 Django Tests:"
echo "---------------"

if python manage.py check --deploy 2>/dev/null; then
    echo "✅ Django deployment check passed"
else
    echo "❌ Django deployment check failed"
    python manage.py check --deploy
fi

if python manage.py migrate --dry-run 2>/dev/null >/dev/null; then
    echo "✅ Migrations look good"
else
    echo "❌ Migration issues detected"
fi

# Test web server
echo ""
echo "🌐 Web Server Test:"
echo "------------------"

if command -v curl >/dev/null 2>&1; then
    if curl -f http://localhost:8080/api/health/ 2>/dev/null >/dev/null; then
        echo "✅ Health endpoint is responding"
    else
        echo "❌ Health endpoint is not responding"
    fi
else
    echo "⚠️  curl not available, cannot test web server"
fi

# System info
echo ""
echo "💻 System Information:"
echo "--------------------"
echo "Python version: $(python --version)"
echo "Django version: $(python -c 'import django; print(django.get_version())' 2>/dev/null || echo 'Not available')"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "Memory usage: $(free -h | grep Mem | awk '{print $3 "/" $2}')" 2>/dev/null || echo "Memory info not available"

echo ""
echo "🏁 Debugging complete!"
echo "If you see any ❌ errors above, those are likely the cause of exit code 3."
