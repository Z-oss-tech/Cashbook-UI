const express = require('express');
const router = express.Router();
const { register, login, updateProfile, getProfile, googleLogin } = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/register', register);
router.post('/login', login);
router.post('/google', googleLogin);
router.post('/update-profile', protect, updateProfile);
router.get('/me', protect, getProfile);

module.exports = router;
