const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development'
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: '🎯 Auditstage Sample Application',
        description: 'This is a sample application deployed via CodeDeploy',
        timestamp: new Date().toISOString(),
        endpoints: {
            health: '/health',
            status: '/status',
            info: '/info'
        }
    });
});

// Status endpoint
app.get('/status', (req, res) => {
    res.json({
        application: 'auditstage-sample',
        status: 'running',
        uptime: process.uptime(),
        memory: {
            used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024 * 100) / 100,
            total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024 * 100) / 100
        },
        cpu: process.cpuUsage(),
        timestamp: new Date().toISOString()
    });
});

// Info endpoint
app.get('/info', (req, res) => {
    res.json({
        name: 'Auditstage Sample Application',
        version: '1.0.0',
        description: 'Sample Node.js application for CodeDeploy testing',
        deployment: {
            method: 'AWS CodeDeploy',
            platform: 'On-Premise',
            automation: 'Terruvim Factory System'
        },
        features: [
            'Health monitoring',
            'PM2 process management',
            'SSM agent integration',
            'CloudWatch metrics',
            'Automated deployment'
        ],
        timestamp: new Date().toISOString()
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        error: 'Something went wrong!',
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        error: 'Route not found',
        path: req.originalUrl,
        timestamp: new Date().toISOString()
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Auditstage sample application running on port ${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
    console.log(`📈 Status: http://localhost:${PORT}/status`);
    console.log(`ℹ️  Info: http://localhost:${PORT}/info`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Received SIGINT, shutting down gracefully');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Received SIGTERM, shutting down gracefully');
    process.exit(0);
});
