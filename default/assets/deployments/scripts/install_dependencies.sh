#!/bin/bash

# Install Dependencies Script for CodeDeploy
# This script installs required dependencies for the application

set -e

echo "📦 Starting dependency installation..."

# Update package manager
if [ -f /etc/debian_version ]; then
    echo "🐧 Detected Debian/Ubuntu system"
    apt-get update -y
    
    # Install Node.js if not present
    if ! command -v node &> /dev/null; then
        echo "📦 Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    # Install PM2 for process management
    if ! command -v pm2 &> /dev/null; then
        echo "📦 Installing PM2..."
        npm install -g pm2
    fi
    
    # Install other dependencies
    apt-get install -y nginx jq curl wget
    
elif [ -f /etc/redhat-release ]; then
    echo "🎩 Detected RedHat/CentOS system"
    yum update -y
    
    # Install Node.js if not present
    if ! command -v node &> /dev/null; then
        echo "📦 Installing Node.js..."
        curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
        yum install -y nodejs
    fi
    
    # Install PM2 for process management
    if ! command -v pm2 &> /dev/null; then
        echo "📦 Installing PM2..."
        npm install -g pm2
    fi
    
    # Install other dependencies
    yum install -y nginx jq curl wget
fi

# Create application user if doesn't exist
if ! id "auditstage" &>/dev/null; then
    echo "👤 Creating application user..."
    useradd -m -s /bin/bash auditstage
fi

# Create application directories
echo "📁 Creating application directories..."
mkdir -p /opt/auditstage/app
mkdir -p /opt/auditstage/logs
mkdir -p /opt/auditstage/config
mkdir -p /opt/auditstage/backups

# Set ownership
chown -R auditstage:auditstage /opt/auditstage

echo "✅ Dependencies installed successfully!"
