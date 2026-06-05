const prisma = require('../config/prisma');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

const register = async (req, res, next) => {
  try {
    const { phone, password, name, email } = req.body;
    if (!phone || !password) {
      res.status(400);
      throw new Error('Phone and password are required');
    }

    let user = await prisma.user.findUnique({
      where: { phone }
    });

    if (user) {
      res.status(400);
      throw new Error('User with this phone number already exists');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    user = await prisma.user.create({
      data: {
        phone,
        passwordHash,
        name: name || null,
        email: email || null,
        authProvider: 'password'
      }
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
        isNewUser: true
      }
    });
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { phone, password } = req.body;
    if (!phone || !password) {
      res.status(400);
      throw new Error('Phone and password are required');
    }

    const user = await prisma.user.findUnique({
      where: { phone }
    });

    if (!user) {
      res.status(401);
      throw new Error('Invalid phone number or password');
    }

    if (user.authProvider !== 'password' || !user.passwordHash) {
      res.status(401);
      throw new Error('Account was created using another method. Please use that method or reset password.');
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);

    if (!isMatch) {
      res.status(401);
      throw new Error('Invalid phone number or password');
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
        isNewUser: false
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
  register,
  login,
  updateProfile,
  getProfile,
  googleLogin
};
