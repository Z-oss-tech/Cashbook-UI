const prisma = require('../config/prisma');
const jwt = require('jsonwebtoken');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

const sendOtp = async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      res.status(400);
      throw new Error('Phone number is required');
    }

    // In a real app, generate a 4 digit OTP and send via SMS
    // We generate a random 4 digit number for testing so it feels real
    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    const otpHash = otp; // Usually bcrypt hash

    const expiration = new Date();
    expiration.setMinutes(expiration.getMinutes() + 10);

    // clear existing OTPs for phone
    await prisma.otpCode.deleteMany({
      where: { phone }
    });

    await prisma.otpCode.create({
      data: {
        phone,
        otpHash,
        expiresAt: expiration
      }
    });

    res.json({ message: 'OTP sent successfully', phone, devOtp: otp }); // devOtp included for dev/testing
  } catch (error) {
    next(error);
  }
};

const verifyOtp = async (req, res, next) => {
  try {
    const { phone, otp } = req.body;
    if (!phone || !otp) {
      res.status(400);
      throw new Error('Phone and OTP are required');
    }

    const otpCode = await prisma.otpCode.findFirst({
      where: {
        phone,
        otpHash: otp, // In prod, use bcrypt.compare
        expiresAt: {
          gt: new Date()
        }
      }
    });

    if (!otpCode) {
      res.status(401);
      throw new Error('Invalid or expired OTP');
    }

    // Check if user exists
    let user = await prisma.user.findUnique({
      where: { phone }
    });

    let isNewUser = false;
    if (!user) {
      isNewUser = true;
      user = await prisma.user.create({
        data: {
          phone,
          authProvider: 'phone'
        }
      });
    }

    // Clean up OTP
    await prisma.otpCode.deleteMany({
      where: { phone }
    });

    res.json({
      success: true,
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        token: generateToken(user.id),
        isNewUser
      }
    });
  } catch (error) {
    next(error);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const { name, email, avatarUrl } = req.body;
    
    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        name,
        email,
        avatarUrl
      }
    });

    res.json({
      success: true,
      data: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        avatarUrl: user.avatarUrl,
      }
    });
  } catch (error) {
    next(error);
  }
};

const getProfile = async (req, res, next) => {
  try {
    res.json({
      success: true,
      data: req.user
    });
  } catch (error) {
    next(error);
  }
};

const googleLogin = async (req, res, next) => {
  try {
    console.log('GOOGLE LOGIN BODY:', req.body);
    const { googleId, email, name, avatarUrl } = req.body;
    
    if (!googleId || !email) {
      res.status(400);
      throw new Error('Google ID and email are required');
    }

    let user = await prisma.user.findFirst({
      where: {
        OR: [
          { googleId },
          { email }
        ]
      }
    });

    let isNewUser = false;
    if (!user) {
      isNewUser = true;
      user = await prisma.user.create({
        data: {
          googleId,
          email,
          name,
          avatarUrl,
          authProvider: 'google'
        }
      });
    } else {
      // Update googleId and authProvider if they signed in with email before
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          googleId,
          authProvider: 'google',
          name: user.name || name,
          avatarUrl: user.avatarUrl || avatarUrl
        }
      });
    }

    res.json({
      success: true,
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        token: generateToken(user.id),
        isNewUser
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  sendOtp,
  verifyOtp,
  updateProfile,
  getProfile,
  googleLogin
};
