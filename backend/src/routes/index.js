const express = require('express');
const router = express.Router();

const authRoutes = require('./auth');
const cashbookRoutes = require('./cashbook');
const recordRoutes = require('./record');
const uploadRoutes = require('./upload');
const appUpdateRoutes = require('./app-update');

router.use('/auth', authRoutes);
router.use('/cashbooks', cashbookRoutes);
router.use('/records', recordRoutes);
router.use('/upload', uploadRoutes);
router.use('/updates', appUpdateRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', timestamp: new Date() });
});

module.exports = router;
