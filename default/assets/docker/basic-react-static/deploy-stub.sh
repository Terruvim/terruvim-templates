#!/bin/bash

# Deploy React stub to S3 CloudFront bucket
# This script uploads a minimal React application as a placeholder

BUCKET_NAME="dev-auditstage-dev-cloudfront-bucket"
REGION="eu-central-1"

echo "🚀 Deploying React stub to CloudFront S3 bucket..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Create a temporary directory for the stub build
TEMP_DIR=$(mktemp -d)
echo "📁 Using temp directory: $TEMP_DIR"

# Create the stub HTML file
cat > "$TEMP_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terruvim Frontend - Development Environment</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        
        .container {
            text-align: center;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            max-width: 600px;
            width: 90%;
        }
        
        .logo {
            font-size: 3rem;
            font-weight: bold;
            margin-bottom: 1rem;
            background: linear-gradient(45deg, #fff, #a8edea);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .subtitle {
            font-size: 1.2rem;
            margin-bottom: 2rem;
            opacity: 0.9;
        }
        
        .status {
            background: rgba(40, 167, 69, 0.2);
            border: 1px solid rgba(40, 167, 69, 0.4);
            border-radius: 10px;
            padding: 1rem;
            margin: 1rem 0;
        }
        
        .info {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            padding: 1rem;
            margin: 1rem 0;
            text-align: left;
        }
        
        .info-row {
            display: flex;
            justify-content: space-between;
            margin: 0.5rem 0;
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 0.9rem;
        }
        
        .label {
            color: #a8edea;
            font-weight: 600;
        }
        
        .value {
            color: #fff;
            opacity: 0.9;
        }
        
        .footer {
            margin-top: 2rem;
            font-size: 0.9rem;
            opacity: 0.7;
        }
        
        .pulse {
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% {
                transform: scale(1);
            }
            50% {
                transform: scale(1.05);
            }
            100% {
                transform: scale(1);
            }
        }
        
        @media (max-width: 768px) {
            .container {
                margin: 1rem;
                padding: 1.5rem;
            }
            
            .logo {
                font-size: 2rem;
            }
            
            .info-row {
                flex-direction: column;
                gap: 0.25rem;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo pulse">TERRUVIM</div>
        <div class="subtitle">Frontend Infrastructure Ready</div>
        
        <div class="status">
            <strong>✅ CloudFront Distribution Active</strong>
            <p>Your static hosting infrastructure is successfully deployed!</p>
        </div>
        
        <div class="info">
            <div class="info-row">
                <span class="label">Environment:</span>
                <span class="value" id="environment">Development</span>
            </div>
            <div class="info-row">
                <span class="label">Deployment:</span>
                <span class="value" id="timestamp">-</span>
            </div>
            <div class="info-row">
                <span class="label">CDN Status:</span>
                <span class="value">Active & Cached</span>
            </div>
            <div class="info-row">
                <span class="label">SSL Certificate:</span>
                <span class="value">Valid & Automated</span>
            </div>
            <div class="info-row">
                <span class="label">WAF Protection:</span>
                <span class="value">Enabled</span>
            </div>
        </div>
        
        <div class="footer">
            <p>Ready for your React application deployment</p>
            <p>This stub will be automatically replaced during CI/CD</p>
        </div>
    </div>
    
    <script>
        // Set deployment timestamp
        document.getElementById('timestamp').textContent = new Date().toISOString();
        
        // Set environment from URL or default
        const hostname = window.location.hostname;
        let environment = 'Development';
        
        if (hostname.includes('prod')) {
            environment = 'Production';
        } else if (hostname.includes('stage')) {
            environment = 'Staging';
        } else if (hostname.includes('dev')) {
            environment = 'Development';
        }
        
        document.getElementById('environment').textContent = environment;
        
        // Add some interactivity
        document.querySelector('.container').addEventListener('click', function() {
            this.style.transform = 'scale(0.98)';
            setTimeout(() => {
                this.style.transform = 'scale(1)';
            }, 150);
        });
        
        console.log('🚀 Terruvim Frontend Infrastructure Ready!');
        console.log('Environment:', environment);
        console.log('Timestamp:', new Date().toISOString());
    </script>
</body>
</html>
EOF

# Create error page
cat > "$TEMP_DIR/error.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Page Not Found - Terruvim</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #ff6b6b 0%, #ffa726 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            margin: 0;
        }
        
        .container {
            text-align: center;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        
        .error-code {
            font-size: 6rem;
            font-weight: bold;
            margin-bottom: 1rem;
        }
        
        .error-message {
            font-size: 1.5rem;
            margin-bottom: 2rem;
        }
        
        .back-link {
            color: white;
            text-decoration: none;
            padding: 1rem 2rem;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            display: inline-block;
            transition: all 0.3s ease;
        }
        
        .back-link:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-code">404</div>
        <div class="error-message">Page Not Found</div>
        <p>The page you're looking for doesn't exist.</p>
        <a href="/" class="back-link">← Back to Home</a>
    </div>
</body>
</html>
EOF

# Sync files to S3
echo "📤 Uploading files to S3 bucket: $BUCKET_NAME"

# Upload index.html
aws s3 cp "$TEMP_DIR/index.html" "s3://$BUCKET_NAME/index.html" \
    --region $REGION \
    --content-type "text/html" \
    --cache-control "max-age=300"

# Upload error.html
aws s3 cp "$TEMP_DIR/error.html" "s3://$BUCKET_NAME/error.html" \
    --region $REGION \
    --content-type "text/html" \
    --cache-control "max-age=300"

# Get CloudFront distribution ID
echo "🔄 Invalidating CloudFront cache..."
DISTRIBUTION_ID=$(aws cloudfront list-distributions \
    --region $REGION \
    --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, '$BUCKET_NAME')].Id" \
    --output text)

if [ -n "$DISTRIBUTION_ID" ] && [ "$DISTRIBUTION_ID" != "None" ]; then
    echo "📋 Found CloudFront distribution: $DISTRIBUTION_ID"
    
    # Create invalidation
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id $DISTRIBUTION_ID \
        --paths "/*" \
        --query "Invalidation.Id" \
        --output text)
    
    echo "🔄 Created invalidation: $INVALIDATION_ID"
    echo "⏳ Cache invalidation may take 5-15 minutes to complete"
else
    echo "⚠️  CloudFront distribution not found - cache will update naturally"
fi

# Clean up
rm -rf "$TEMP_DIR"

echo "✅ React stub deployment completed!"
echo "🌐 Your CloudFront endpoint should now serve the stub application"
echo "🚀 Ready for React application deployment via CI/CD pipeline"
