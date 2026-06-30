const express = require('express');
const router = express.Router();
const appUpdateController = require('../controllers/appUpdateController');

// Open endpoint for checking updates (no auth required)
router.get('/latest', appUpdateController.getLatestUpdate);

// Admin/Testing endpoint to create/seed updates
router.post('/', appUpdateController.createUpdate);

module.exports = router;
