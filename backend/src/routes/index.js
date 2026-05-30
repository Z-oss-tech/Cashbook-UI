const express = require('express');
const router = express.Router();

const authRoutes = require('./auth');
const cashbookRoutes = require('./cashbook');
const recordRoutes = require('./record');
const uploadRoutes = require('./upload');

router.use('/auth', authRoutes);
router.use('/cashbooks', cashbookRoutes);
router.use('/records', recordRoutes);
router.use('/upload', uploadRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', timestamp: new Date() });
});

module.exports = router;
