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
    const { username, password, name, email } = req.body;
    if (!username || !password) {
      res.status(400);
      throw new Error('Username and password are required');
    }

    let user = await prisma.user.findUnique({
      where: { username }
    });

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    let isNewUser = false;

    if (user) {
      // Allow legacy OTP users to set a password
      if (user.authProvider === 'phone' && !user.passwordHash) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: {
            passwordHash,
            authProvider: 'password',
            name: name || user.name,
            email: email || user.email
          }
        });
      } else {
        res.status(400);
        throw new Error('User with this username already exists');
      }
    } else {
      isNewUser = true;
      user = await prisma.user.create({
        data: {
          username,
          passwordHash,
          name: name || null,
          email: email || null,
          authProvider: 'password'
        }
      });
    }

    res.json({
      success: true,
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        username: user.username,
        avatarUrl: user.avatarUrl,
        token: generateToken(user.id),
        isNewUser: isNewUser
      }
    });
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      res.status(400);
      throw new Error('Username and password are required');
    }

    const user = await prisma.user.findUnique({
      where: { username }
    });

    if (!user) {
      res.status(401);
      throw new Error('User not found, please register first.');
    }

    if (user.authProvider !== 'password' || !user.passwordHash) {
      res.status(401);
      throw new Error('Please go to Register to set a new password for your old account.');
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);

    if (!isMatch) {
      res.status(401);
      throw new Error('Invalid username or password');
    }

    res.json({
      success: true,
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        username: user.username,
        avatarUrl: user.avatarUrl,
        token: generateToken(user.id),
        isNewUser: !user.name
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
        username: user.username,
        email: user.email,
        avatarUrl: user.avatarUrl,
      }
    });
  } catch (error) {
    if (error.code === 'P2002') {
      res.status(400);
      return next(new Error('This email address is already registered to another account.'));
    }
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
        username: user.username,
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
