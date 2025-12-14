# Auditstage Sample Application

This is a sample Node.js application designed for testing CodeDeploy deployments with the Terruvim factory system.

## Features

- 🌐 Express.js web server
- 🔒 Security middleware (Helmet, CORS)
- 📊 Health monitoring endpoints
- 🚀 PM2 process management ready
- 📈 System status reporting
- 🎯 CodeDeploy lifecycle hooks integration

## Endpoints

- `GET /` - Application information
- `GET /health` - Health check endpoint
- `GET /status` - Detailed application status
- `GET /info` - Application and deployment information

## Deployment

This application is designed to be deployed using AWS CodeDeploy with the following lifecycle:

1. **BeforeInstall** - Prepare system and install dependencies
2. **AfterInstall** - Set up permissions and configuration
3. **ApplicationStart** - Start the application using PM2
4. **ValidateService** - Verify deployment success

## Local Development

```bash
# Install dependencies
npm install

# Start application
npm start

# Application will be available at http://localhost:3000
```

## Production Deployment

The application is automatically deployed to `/opt/auditstage/app/` and managed by PM2 with:

- Process clustering for high availability
- Automatic restarts on failure
- Log management and rotation
- Health monitoring integration

## Monitoring

- Logs: `/opt/auditstage/logs/`
- Health check: `http://localhost:3000/health`
- Status monitoring: `http://localhost:3000/status`
- PM2 monitoring: `pm2 status`

## Environment Variables

- `NODE_ENV` - Application environment (production/development)
- `PORT` - Application port (default: 3000)
- `LOG_LEVEL` - Logging level (default: info)
