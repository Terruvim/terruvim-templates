const express = require('express');
const app = express();
const PORT = process.env.PORT || 8080;

// Health check endpoint for ELB
app.get('/authentication/up', (req, res) => {
  res.json({ status: 'healthy', service: 'auth-service-placeholder', timestamp: new Date().toISOString() });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({ message: 'Auth Service Placeholder - Ready for deployment!', service: 'auth-service', environment: process.env.NODE_ENV || 'development' });
});

// Authentication endpoints placeholders
app.get('/authentication*', (req, res) => {
  res.json({ message: 'Auth service is being deployed. Please wait for CI/CD completion.', endpoint: req.path });
});

// Catch all other routes
app.get('*', (req, res) => {
  res.json({ message: 'Auth Service Placeholder is running!', requested: req.path });
});

app.listen(PORT, () => {
  console.log(`Auth Service Placeholder started on port ${PORT}`);
});
