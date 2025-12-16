import jwt from 'jsonwebtoken';
import User from '../models/User.js';

export const authMiddleware = async (req, res, next) => {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'No token provided' });
    }
    
    const token = header.split(' ')[1];
    const secret = process.env.JWT_SECRET;
    
    if (!secret) {
      throw new Error('JWT_SECRET not configured');
    }
    
    const payload = jwt.verify(token, secret);
    
    if (!payload?.id) {
      return res.status(401).json({ message: 'Invalid token' });
    }
    
    const user = await User.findById(payload.id).select('-passwordHash');
    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }
    
    req.user = user;
    next();
  } catch (err) {
    console.error('Auth middleware error:', err);
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ message: 'Invalid token' });
    }
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expired' });
    }
    return res.status(401).json({ message: 'Unauthorized', error: err.message });
  }
};

