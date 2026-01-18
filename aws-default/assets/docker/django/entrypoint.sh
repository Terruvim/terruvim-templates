#!/bin/bash
# Django entrypoint script for ECS/Docker

set -e

echo "🚀 Starting Django application..."

# Wait for database to be ready
echo "⏳ Waiting for PostgreSQL..."
while ! nc -z ${DB_HOST:-localhost} ${DB_PORT:-5432}; do
    sleep 1
done
echo "✅ PostgreSQL is ready!"

# Run migrations
echo "📦 Running database migrations..."
python manage.py migrate --noinput

# Collect static files
echo "📁 Collecting static files..."
python manage.py collectstatic --noinput

# Create superuser if not exists (optional, for dev)
if [ "$DJANGO_SUPERUSER_EMAIL" ]; then
    echo "👤 Creating superuser..."
    python manage.py createsuperuser --noinput || true
fi

echo "✅ Django initialization complete!"

# Start the application
exec "$@"
