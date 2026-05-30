const express = require('express');
const router = express.Router();
const { sendOtp, verifyOtp, updateProfile, getProfile, googleLogin } = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/send-otp', sendOtp);
router.post('/resend-otp', sendOtp);
router.post('/verify-otp', verifyOtp);
router.post('/google', googleLogin);
router.post('/update-profile', protect, updateProfile);
router.get('/me', protect, getProfile);

module.exports = router;
