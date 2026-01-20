#!/bin/bash
# Quick test script to reproduce the issue locally

echo "🧪 Local Test for ECS Exit Code 3 Issue"
echo "======================================="

# Build the image
echo "🏗️  Building Docker image..."
docker build -t django-test .

# Test with minimal environment (should fail with meaningful error)
echo ""
echo "🔍 Test 1: Minimal environment (should show missing vars)"
docker run --rm \
  -e DEBUG=True \
  django-test echo "Container started successfully"

# Test with complete environment
echo ""
echo "🔍 Test 2: Complete environment (should work with SQLite)"
docker run --rm \
  -e DEBUG=True \
  -e SECRET_KEY=test-secret-key-for-local-testing \
  -e ALLOWED_HOSTS=localhost,127.0.0.1 \
  -e DATABASE_URL=sqlite:///tmp/test.db \
  -e DJANGO_SETTINGS_MODULE=config.settings \
  -p 8080:8080 \
  django-test python manage.py check

# Test entrypoint script directly
echo ""
echo "🔍 Test 3: Entrypoint script test"
docker run --rm \
  -e DEBUG=True \
  -e SECRET_KEY=test-secret-key-for-local-testing \
  -e ALLOWED_HOSTS=localhost,127.0.0.1 \
  -e DATABASE_URL=sqlite:///tmp/test.db \
  -e DJANGO_SETTINGS_MODULE=config.settings \
  django-test /entrypoint.sh python --version

echo ""
echo "🔍 Test 4: Full application startup (background)"
CONTAINER_ID=$(docker run -d \
  -e DEBUG=True \
  -e SECRET_KEY=test-secret-key-for-local-testing \
  -e ALLOWED_HOSTS=localhost,127.0.0.1 \
  -e DATABASE_URL=sqlite:///tmp/test.db \
  -e DJANGO_SETTINGS_MODULE=config.settings \
  -p 8080:8080 \
  django-test)

echo "Container ID: $CONTAINER_ID"
echo "Waiting for startup..."
sleep 10

echo "Container status:"
docker ps -f id=$CONTAINER_ID

echo ""
echo "Container logs:"
docker logs $CONTAINER_ID

echo ""
echo "Testing health endpoint:"
curl -f http://localhost:8080/api/health/ || echo "Health check failed"

echo ""
echo "Cleaning up..."
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID

echo ""
echo "✅ Local testing complete"
