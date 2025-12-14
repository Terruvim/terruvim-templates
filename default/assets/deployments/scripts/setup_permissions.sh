#!/bin/bash

# Setup Permissions Script for CodeDeploy
# This script sets up proper file permissions and ownership

set -e

echo "🔐 Setting up permissions..."

# Set ownership for application directory
echo "👤 Setting ownership for application files..."
chown -R auditstage:auditstage /opt/auditstage

# Set proper permissions for directories
echo "📁 Setting directory permissions..."
find /opt/auditstage -type d -exec chmod 755 {} \;

# Set proper permissions for files
echo "📄 Setting file permissions..."
find /opt/auditstage -type f -exec chmod 644 {} \;

# Make scripts executable
echo "🚀 Making scripts executable..."
find /opt/auditstage -name "*.sh" -exec chmod +x {} \;

# Set specific permissions for application files
if [ -d "/opt/auditstage/app" ]; then
    # Make any executable files in bin/ directory executable
    if [ -d "/opt/auditstage/app/bin" ]; then
        chmod +x /opt/auditstage/app/bin/* 2>/dev/null || true
    fi
    
    # Set permissions for node_modules if exists
    if [ -d "/opt/auditstage/app/node_modules" ]; then
        find /opt/auditstage/app/node_modules -name "*.js" -exec chmod +x {} \; 2>/dev/null || true
    fi
fi

# Setup log directory permissions
echo "📝 Setting up log permissions..."
mkdir -p /opt/auditstage/logs
chmod 755 /opt/auditstage/logs
chown auditstage:auditstage /opt/auditstage/logs

# Setup configuration directory permissions
echo "⚙️  Setting up config permissions..."
chmod 750 /opt/auditstage/config
chown auditstage:auditstage /opt/auditstage/config

# Set permissions for any config files
find /opt/auditstage/config -type f -exec chmod 640 {} \; 2>/dev/null || true

# Setup systemd service if it exists
if [ -f "/etc/systemd/system/auditstage.service" ]; then
    echo "🔧 Setting up systemd service permissions..."
    chmod 644 /etc/systemd/system/auditstage.service
    systemctl daemon-reload
fi

# Setup nginx configuration if it exists
if [ -f "/etc/nginx/sites-available/auditstage" ]; then
    echo "🌐 Setting up nginx configuration..."
    chmod 644 /etc/nginx/sites-available/auditstage
    
    # Enable site if not already enabled
    if [ ! -L "/etc/nginx/sites-enabled/auditstage" ]; then
        ln -sf /etc/nginx/sites-available/auditstage /etc/nginx/sites-enabled/
    fi
fi

# Add auditstage user to necessary groups
echo "👥 Adding user to required groups..."
usermod -a -G www-data auditstage 2>/dev/null || true

echo "✅ Permissions set up successfully!"
