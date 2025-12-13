// CRITICAL: Set timezone FIRST, before any requires!
process.env.TZ = 'Asia/Ho_Chi_Minh';

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const prisma = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' })); // For base64 images
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/floors', require('./routes/floors'));
app.use('/api/tables', require('./routes/tables'));
app.use('/api/menu', require('./routes/menu'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/reports', require('./routes/reports'));
app.use('/api/table-sessions', require('./routes/tableSessions'));

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('SIGTERM received, closing server...');
    await prisma.$disconnect();
    process.exit(0);
});

process.on('SIGINT', async () => {
    console.log('SIGINT received, closing server...');
    await prisma.$disconnect();
    process.exit(0);
});

// Start server
app.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════╗
║   Flutter POS Backend API Server     ║
║   Port: ${PORT}                          ║
║   Environment: ${process.env.NODE_ENV}           ║
╚═══════════════════════════════════════╝
  `);
});

module.exports = app;
