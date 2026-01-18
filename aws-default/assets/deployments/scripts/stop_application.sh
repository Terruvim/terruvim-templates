#!/bin/bash

# Stop Application Script for CodeDeploy
# This script stops the running application gracefully

set -e

echo "🛑 Stopping application..."

# Check if PM2 is running
if command -v pm2 &> /dev/null; then
    echo "🔄 Stopping PM2 processes..."
    
    # Stop all processes for auditstage
    pm2 stop auditstage 2>/dev/null || echo "ℹ️  No auditstage process found"
    pm2 delete auditstage 2>/dev/null || echo "ℹ️  No auditstage process to delete"
    
    # Save PM2 process list
    pm2 save 2>/dev/null || echo "ℹ️  PM2 save not needed"
fi

# Stop nginx if it's running
if systemctl is-active --quiet nginx; then
    echo "🌐 Stopping nginx..."
    systemctl stop nginx
fi

# Kill any remaining processes on common ports
echo "🔍 Checking for processes on application ports..."
ports=(3000 4000 5000 8080 8000)

for port in "${ports[@]}"; do
    pid=$(lsof -ti:$port 2>/dev/null || true)
    if [ ! -z "$pid" ]; then
        echo "🔫 Killing process on port $port (PID: $pid)"
        kill -TERM $pid 2>/dev/null || true
        sleep 2
        kill -KILL $pid 2>/dev/null || true
    fi
done

# Create backup of current deployment if it exists
if [ -d "/opt/auditstage/app" ] && [ "$(ls -A /opt/auditstage/app)" ]; then
    backup_dir="/opt/auditstage/backups/$(date +%Y%m%d_%H%M%S)"
    echo "💾 Creating backup at $backup_dir..."
    mkdir -p "$backup_dir"
    cp -r /opt/auditstage/app/* "$backup_dir/" 2>/dev/null || true
    
    # Keep only last 5 backups
    cd /opt/auditstage/backups
    ls -t | tail -n +6 | xargs -r rm -rf
fi

echo "✅ Application stopped successfully!"
