#!/bin/bash
# Test Django admin health check endpoint locally

echo "🔍 Testing Django Admin Health Check"
echo "======================================"
echo ""

# Set environment variables
export FORCE_SCRIPT_NAME="/admin"
export DJANGO_STATIC_URL="/admin/static/"
export PORT=8080
export DEBUG=False
export SECRET_KEY="test-secret-key"
export ALLOWED_HOSTS="*"
export DATABASE_URL="sqlite:///db.sqlite3"

echo "📝 Environment:"
echo "  FORCE_SCRIPT_NAME: $FORCE_SCRIPT_NAME"
echo "  PORT: $PORT"
echo ""

# Start Django development server in background
echo "🚀 Starting Django server..."
cd "$(dirname "$0")"
python manage.py runserver 0.0.0.0:$PORT > /dev/null 2>&1 &
SERVER_PID=$!

# Wait for server to start
sleep 3

echo "✅ Server started (PID: $SERVER_PID)"
echo ""

# Test health check endpoints
echo "🧪 Testing health check endpoints:"
echo ""

echo "1️⃣  Test: /admin/health/ (what ALB sends)"
curl -s -o /dev/null -w "   Status: %{http_code}\n" http://localhost:$PORT/admin/health/
curl -s http://localhost:$PORT/admin/health/
echo ""
echo ""

echo "2️⃣  Test: /health/ (without prefix)"
curl -s -o /dev/null -w "   Status: %{http_code}\n" http://localhost:$PORT/health/
curl -s http://localhost:$PORT/health/
echo ""
echo ""

echo "3️⃣  Test: /admin/ (admin login page)"
curl -s -o /dev/null -w "   Status: %{http_code}\n" http://localhost:$PORT/admin/
echo ""

echo "4️⃣  Test: /admin/static/admin/css/base.css (static file)"
curl -s -o /dev/null -w "   Status: %{http_code}\n" http://localhost:$PORT/admin/static/admin/css/base.css
echo ""

# Cleanup
echo ""
echo "🛑 Stopping server..."
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null

echo "✅ Test complete!"
