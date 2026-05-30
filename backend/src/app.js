const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

const routes = require('./routes');
const { errorHandler } = require('./middlewares/errorMiddleware');

const app = express();

// Middlewares
app.use(helmet());
app.use(cors());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per `window` (here, per 15 minutes)
  message: 'Too many requests from this IP, please try again after 15 minutes',
});
app.use('/api', limiter);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Prisma client attached to app (optional, or import it where needed)
const prisma = new PrismaClient();
app.locals.prisma = prisma;

// Routes
app.use('/api', routes);

// Global Error Handler
app.use(errorHandler);

module.exports = app;
