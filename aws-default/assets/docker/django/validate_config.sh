#!/bin/bash
# Configuration validation script for Django ECS deployment

set -e

echo "🔍 Django ECS Configuration Validation"
echo "======================================"

CONFIG_DIR="/Users/anton/Desktop/CURRENT/terruvim-infrastructure/deployments/project42/envs"
DJANGO_DIR="/Users/anton/Desktop/CURRENT/terruvim-infrastructure/deployments/project42/assets/docker/django"

# Check if files exist
echo "📁 Checking configuration files..."
if [ ! -f "$CONFIG_DIR/infrastructure.json" ]; then
    echo "❌ infrastructure.json not found"
    exit 1
fi

if [ ! -f "$CONFIG_DIR/infrastructure.dev.json" ]; then
    echo "❌ infrastructure.dev.json not found"
    exit 1
fi

echo "✅ Configuration files found"

# Check Docker configuration
echo ""
echo "🐳 Checking Docker configuration..."
cd "$DJANGO_DIR"

if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile not found"
    exit 1
fi

if [ ! -f "entrypoint.sh" ]; then
    echo "❌ entrypoint.sh not found"
    exit 1
fi

if [ ! -f "requirements.txt" ]; then
    echo "❌ requirements.txt not found"
    exit 1
fi

echo "✅ Docker files found"

# Check Django structure
echo ""
echo "🎯 Checking Django structure..."
if [ ! -d "config" ]; then
    echo "❌ config directory not found"
    exit 1
fi

if [ ! -f "config/settings.py" ]; then
    echo "❌ config/settings.py not found"
    exit 1
fi

if [ ! -f "config/settings/production.py" ]; then
    echo "❌ config/settings/production.py not found"
    exit 1
fi

if [ ! -f "config/urls.py" ]; then
    echo "❌ config/urls.py not found"
    exit 1
fi

if [ ! -f "config/wsgi.py" ]; then
    echo "❌ config/wsgi.py not found"
    exit 1
fi

if [ ! -f "manage.py" ]; then
    echo "❌ manage.py not found"
    exit 1
fi

echo "✅ Django structure is valid"

# Validate Dockerfile
echo ""
echo "🔍 Validating Dockerfile..."
if grep -q "EXPOSE 8080" Dockerfile; then
    echo "✅ Dockerfile exposes port 8080"
else
    echo "❌ Dockerfile should expose port 8080"
fi

if grep -q "ENTRYPOINT.*entrypoint.sh" Dockerfile; then
    echo "✅ Dockerfile uses entrypoint script"
else
    echo "❌ Dockerfile should use entrypoint script"
fi

if grep -q "netcat" Dockerfile; then
    echo "✅ Dockerfile includes netcat for DB checks"
else
    echo "❌ Dockerfile should include netcat-openbsd"
fi

# Validate entrypoint script
echo ""
echo "🔍 Validating entrypoint script..."
if grep -q "DATABASE_URL.*DB_HOST" entrypoint.sh; then
    echo "✅ Entrypoint checks for database environment variables"
else
    echo "❌ Entrypoint should check DATABASE_URL or DB_HOST"
fi

if grep -q "nc -z" entrypoint.sh; then
    echo "✅ Entrypoint tests database connection"
else
    echo "❌ Entrypoint should test database connection with netcat"
fi

if grep -q "python manage.py migrate" entrypoint.sh; then
    echo "✅ Entrypoint runs database migrations"
else
    echo "❌ Entrypoint should run database migrations"
fi

# Validate ECS configuration
echo ""
echo "🔍 Validating ECS configuration..."
cd "$CONFIG_DIR"

if grep -q '"port": 8080' infrastructure.dev.json; then
    echo "✅ ECS service configured for port 8080"
else
    echo "❌ ECS service should use port 8080"
fi

if grep -q '"healthCheckPath": "/api/health/"' infrastructure.dev.json; then
    echo "✅ Health check path is correct"
else
    echo "❌ Health check should use /api/health/ endpoint"
fi

if grep -q 'DATABASE_URL' infrastructure.dev.json; then
    echo "✅ DATABASE_URL environment variable configured"
else
    echo "❌ DATABASE_URL should be configured for Django"
fi

if grep -q '"SECRET_KEY"' infrastructure.dev.json; then
    echo "✅ SECRET_KEY environment variable configured"
else
    echo "❌ SECRET_KEY should be configured"
fi

# Check secrets configuration
echo ""
echo "🔍 Validating secrets configuration..."
if grep -q '"DJANGO_SETTINGS_MODULE": "config.settings"' infrastructure.json; then
    echo "✅ Django settings module is correct"
else
    echo "❌ Django settings module should be config.settings"
fi

if grep -q '"DJANGO_DEBUG": "False"' infrastructure.json; then
    echo "✅ Django debug is disabled in production"
else
    echo "❌ Django debug should be False in production"
fi

echo ""
echo "🎉 Configuration validation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Update AWS Secrets Manager with corrected values"
echo "2. Rebuild and push Docker image"
echo "3. Update ECS service"
echo "4. Monitor CloudWatch logs for any remaining issues"
echo ""
echo "💡 Use the debug.sh script to troubleshoot container issues"
echo "💡 Use the deploy.sh script to automate deployment"
