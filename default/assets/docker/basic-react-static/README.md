# Terruvim Frontend Infrastructure Stub

This directory contains the frontend infrastructure stub for the Terruvim platform, designed to provide a safety net for CloudFront deployments.

## 🏗️ Infrastructure Status

✅ **CloudFront Distribution**: `E1FLO6CEGU282V` - DEPLOYED  
🌐 **Primary URL**: https://dcf76sck7bj06.cloudfront.net  
🎯 **Custom Domain**: https://app.dev.d3qdzipj8ua01l.com  
🪣 **S3 Bucket**: `dev-auditstage-dev-cloudfront-bucket`  
🔒 **SSL Certificate**: ACM-managed, auto-renewal enabled  
🛡️ **WAF Protection**: Enabled with geo-blocking and rate limiting  

## 📁 Files Overview

```
basic-react-static/
├── index.html          # Main landing page with Terruvim branding
├── error.html          # 404 error page
├── package.json        # React project configuration
├── deploy-stub.sh      # Full deployment script (requires AWS CLI)
├── stub.sh            # Info script (current deployment status)
└── README.md          # This documentation
```

## 🚀 Architecture Integration

This stub is part of the **refactored CloudFront infrastructure**:

1. **S3StaticHostingFactory** - Simplified for static hosting only
2. **CloudFrontCodePipelineFactory** - Dedicated CI/CD pipeline
3. **Enhanced Buildspec** - Multi-format support (React, static HTML, stub fallback)

## 🔄 Deployment Process

### Automatic (CI/CD Pipeline)
The `CloudFrontCodePipelineFactory` will automatically:
1. Detect application type (React, static HTML, or fallback to stub)
2. Build the application
3. Deploy to S3
4. Invalidate CloudFront cache

### Manual Deployment
When AWS CLI is configured:

```bash
# Upload stub files
aws s3 cp index.html s3://dev-auditstage-dev-cloudfront-bucket/ --content-type 'text/html'
aws s3 cp error.html s3://dev-auditstage-dev-cloudfront-bucket/ --content-type 'text/html'

# Invalidate cache
aws cloudfront create-invalidation --distribution-id E1FLO6CEGU282V --paths '/*'
```

## 🎨 Stub Features

The frontend stub provides:

- **Modern responsive design** with glassmorphism styling
- **Environment detection** (dev/stage/prod) from hostname
- **Real-time deployment timestamp**
- **Infrastructure status display**
- **Mobile-responsive layout**
- **Interactive animations**

## 🔧 Technical Details

### CloudFront Configuration
- **Price Class**: PriceClass_100 (US, Canada, Europe)
- **HTTP Version**: HTTP/2
- **IPv6**: Disabled
- **Compression**: Enabled
- **Default Root Object**: index.html
- **Error Pages**: 403, 404 → index.html (SPA routing support)

### Security Features
- **WAF v2**: Rate limiting (1000 RPM), geo-blocking (CN, RU, KP)
- **HTTPS Only**: Redirect HTTP to HTTPS
- **TLS**: Minimum TLSv1.2_2021
- **CORS**: Configured for cross-origin requests

### Monitoring
- **CloudWatch Alarms**: 13 metrics monitored
- **Dashboard**: Custom CloudWatch dashboard
- **Logging**: Configurable (currently disabled)

## 🔗 Related Infrastructure

This stub works with:
- **ECS Services**: Backend API endpoints
- **Aurora Serverless**: Database layer
- **Route53**: DNS management
- **ACM**: SSL certificate automation
- **WAF**: Web application firewall

## 🚀 Next Steps

1. **Configure AWS CLI** for file uploads
2. **Test deployment** by uploading stub files
3. **Verify SSL certificate** on custom domain
4. **Set up CI/CD** with CloudFrontCodePipelineFactory
5. **Replace stub** with your React application

## 🎯 Success Criteria

- ✅ CloudFront distribution deployed and active
- ✅ SSL certificate provisioned and validated
- ✅ Custom domain routing configured
- ✅ WAF protection enabled
- ✅ S3 bucket secure and accessible
- ✅ Error handling configured (404 → index.html)
- 🔄 Stub files uploaded (pending AWS CLI config)
- 🔄 CI/CD pipeline testing

---

**Terruvim Frontend Infrastructure** - Ready for production React deployment!
