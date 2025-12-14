#!/bin/bash

# Start Application Script for CodeDeploy
# This script starts the application after deployment

set -e

echo "🚀 Starting application..."

# Change to application directory
cd /opt/auditstage/app

# Switch to auditstage user for running the application
sudo -u auditstage bash << 'EOF'

# Set environment variables
export NODE_ENV=production
export PORT=3000
export LOG_LEVEL=info
export APP_NAME=auditstage

# Install npm dependencies if package.json exists
if [ -f "package.json" ]; then
    echo "📦 Installing npm dependencies..."
    npm ci --only=production
fi

# Start application with PM2
if command -v pm2 &> /dev/null; then
    echo "🔄 Starting application with PM2..."
    
    # Create PM2 ecosystem file if it doesn't exist
    if [ ! -f "ecosystem.config.js" ]; then
        cat > ecosystem.config.js << 'ECOSYSTEM_EOF'
module.exports = {
  apps: [{
    name: 'auditstage',
    script: './index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/opt/auditstage/logs/error.log',
    out_file: '/opt/auditstage/logs/access.log',
    log_file: '/opt/auditstage/logs/combined.log',
    time: true,
    watch: false,
    max_restarts: 10,
    min_uptime: '10s'
  }]
}
ECOSYSTEM_EOF
    fi
    
    # Start with PM2
    pm2 start ecosystem.config.js
    pm2 save
    
    # Setup PM2 startup script
    pm2 startup systemd -u auditstage --hp /home/auditstage
    
else
    echo "⚠️  PM2 not found, starting application directly..."
    # Fallback to direct node execution
    nohup node index.js > /opt/auditstage/logs/application.log 2>&1 &
fi

EOF

# Start nginx if configuration exists
if [ -f "/etc/nginx/sites-available/auditstage" ]; then
    echo "🌐 Starting nginx..."
    
    # Test nginx configuration
    nginx -t
    
    # Start nginx
    systemctl start nginx
    systemctl enable nginx
fi

# Wait a moment for the application to start
sleep 5

echo "✅ Application started successfully!"

# Show status
echo "📊 Application status:"
sudo -u auditstage pm2 status 2>/dev/null || echo "ℹ️  PM2 status not available"

# Check if application is responding
if curl -f http://localhost:3000/health 2>/dev/null; then
    echo "✅ Health check passed!"
else
    echo "⚠️  Health check endpoint not available or not responding"
fi
