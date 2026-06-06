const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

const routes = require('./routes');
const { errorHandler } = require('./middlewares/errorMiddleware');

const app = express();

// Trust the reverse proxy (Crucial for Render/Heroku so rate limiting works per user IP)
app.set('trust proxy', 1);

// Middlewares
app.use(helmet());
app.use(cors());

// Health Check Endpoints (Root and /health) for UptimeRobot and Render
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Cashbook API is up and running'
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString()
  });
});

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per `window`
  message: 'Too many requests from this IP, please try again after 15 minutes',
});
app.use('/api', limiter);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Prisma client attached to app
const prisma = new PrismaClient();
app.locals.prisma = prisma;

// Routes
app.use('/api', routes);

// Global Error Handler
app.use(errorHandler);

module.exports = app;
