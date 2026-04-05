const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Health check endpoint for Kubernetes
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy' });
});

// Readiness check endpoint for Kubernetes
app.get('/ready', (req, res) => {
    res.status(200).json({ ready: true });
});

// Metrics endpoint for Prometheus
app.get('/metrics', (req, res) => {
    res.set('Content-Type', 'text/plain');
    res.send(`# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/",status="200"} 1
`);
});

// Main endpoint
app.get('/', (req, res) => {
    res.send('Hello, World! This is a cloud-native application.');
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`Readiness check: http://localhost:${PORT}/ready`);
});
