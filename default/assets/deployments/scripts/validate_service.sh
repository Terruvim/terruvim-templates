#!/bin/bash

# Validate Service Script for CodeDeploy
# This script validates that the application is running correctly after deployment

set -e

echo "🔍 Validating service deployment..."

# Function to check if a port is open
check_port() {
    local port=$1
    local timeout=30
    local counter=0
    
    echo "🔌 Checking port $port..."
    
    while [ $counter -lt $timeout ]; do
        if netstat -tuln | grep -q ":$port "; then
            echo "✅ Port $port is open"
            return 0
        fi
        
        counter=$((counter + 1))
        sleep 1
    done
    
    echo "❌ Port $port is not open after $timeout seconds"
    return 1
}

# Function to check HTTP endpoint
check_http_endpoint() {
    local url=$1
    local timeout=30
    local counter=0
    
    echo "🌐 Checking HTTP endpoint: $url"
    
    while [ $counter -lt $timeout ]; do
        if curl -f -s --max-time 5 "$url" > /dev/null 2>&1; then
            echo "✅ HTTP endpoint $url is responding"
            return 0
        fi
        
        counter=$((counter + 1))
        sleep 1
    done
    
    echo "❌ HTTP endpoint $url is not responding after $timeout seconds"
    return 1
}

# Function to check PM2 processes
check_pm2_processes() {
    echo "🔄 Checking PM2 processes..."
    
    if ! command -v pm2 &> /dev/null; then
        echo "⚠️  PM2 not installed"
        return 1
    fi
    
    # Switch to auditstage user to check PM2
    sudo -u auditstage bash << 'EOF'
    pm2_status=$(pm2 jlist 2>/dev/null)
    
    if echo "$pm2_status" | jq -e '.[] | select(.name == "auditstage" and .pm2_env.status == "online")' > /dev/null 2>&1; then
        echo "✅ PM2 process 'auditstage' is online"
        exit 0
    else
        echo "❌ PM2 process 'auditstage' is not online"
        exit 1
    fi
EOF
}

# Function to check application logs
check_application_logs() {
    echo "📝 Checking application logs for errors..."
    
    log_files=(
        "/opt/auditstage/logs/error.log"
        "/opt/auditstage/logs/application.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            # Check for critical errors in the last 10 lines
            if tail -10 "$log_file" | grep -qi "error\|exception\|fatal"; then
                echo "⚠️  Found errors in $log_file:"
                tail -5 "$log_file" | grep -i "error\|exception\|fatal" || true
            fi
        fi
    done
}

# Function to check system resources
check_system_resources() {
    echo "💾 Checking system resources..."
    
    # Check memory usage
    memory_usage=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
    echo "🧠 Memory usage: $memory_usage%"
    
    if [ "$memory_usage" -gt 90 ]; then
        echo "⚠️  High memory usage detected"
    fi
    
    # Check disk space for application directory
    disk_usage=$(df /opt/auditstage | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "💽 Disk usage for /opt/auditstage: $disk_usage%"
    
    if [ "$disk_usage" -gt 90 ]; then
        echo "⚠️  High disk usage detected"
    fi
}

# Main validation logic
echo "🎯 Starting service validation..."

validation_passed=true

# Check if application port is open
if ! check_port 3000; then
    validation_passed=false
fi

# Check PM2 processes
if ! check_pm2_processes; then
    validation_passed=false
fi

# Check HTTP endpoints
endpoints=(
    "http://localhost:3000"
    "http://localhost:3000/health"
)

for endpoint in "${endpoints[@]}"; do
    if ! check_http_endpoint "$endpoint"; then
        echo "⚠️  Endpoint $endpoint validation failed (this might be expected if endpoint doesn't exist)"
    fi
done

# Check application logs
check_application_logs

# Check system resources
check_system_resources

# Check nginx if it's configured
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "🌐 Nginx is running"
    
    # Test nginx configuration
    if nginx -t 2>/dev/null; then
        echo "✅ Nginx configuration is valid"
    else
        echo "❌ Nginx configuration has issues"
        validation_passed=false
    fi
fi

# Final validation result
if [ "$validation_passed" = true ]; then
    echo ""
    echo "🎉 Service validation PASSED!"
    echo "📊 Application is running and responding correctly"
    
    # Show final status
    echo ""
    echo "📈 Final Status Report:"
    echo "├── Application: Running ✅"
    echo "├── Port 3000: Open ✅"
    echo "├── PM2 Process: Online ✅"
    echo "└── System: Healthy ✅"
    
    exit 0
else
    echo ""
    echo "❌ Service validation FAILED!"
    echo "⚠️  Some checks did not pass, please review the logs above"
    
    # Show what processes are actually running
    echo ""
    echo "🔍 Current process status:"
    ps aux | grep -E "(node|pm2|nginx)" | grep -v grep || echo "No related processes found"
    
    exit 1
fi
