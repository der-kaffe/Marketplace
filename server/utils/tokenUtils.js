// utils/tokenUtils.js
const jwt = require('jsonwebtoken');
const { secureLog } = require('../middleware/secureLogger');

// Generar par de tokens (access + refresh)
const generateTokenPair = (payload) => {
  try {
    const accessToken = jwt.sign(
      payload, 
      process.env.JWT_SECRET, 
      { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
    );
    
    const refreshToken = jwt.sign(
      { ...payload, type: 'refresh' }, 
      process.env.JWT_REFRESH_SECRET, 
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
    );
    
    return { accessToken, refreshToken };
  } catch (error) {
    secureLog.error('Error generando tokens', error);
    throw new Error('Error interno al generar tokens');
  }
};

// Verificar refresh token
const verifyRefreshToken = (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
    
    // Verificar que es un refresh token
    if (decoded.type !== 'refresh') {
      throw new Error('Token no es de tipo refresh');
    }
    
    // Remover el campo type antes de retornar
    const { type, ...payload } = decoded;
    return payload;
  } catch (error) {
    secureLog.warn('Intento de usar refresh token inválido', { 
      error: error.message,
      tokenPreview: token ? token.substring(0, 20) + '...' : 'null'
    });
    throw error;
  }
};

// Verificar si un token está próximo a expirar
const isTokenNearExpiry = (token, thresholdMinutes = 5) => {
  try {
    const decoded = jwt.decode(token);
    if (!decoded || !decoded.exp) return true;
    
    const now = Math.floor(Date.now() / 1000);
    const timeUntilExpiry = decoded.exp - now;
    const thresholdSeconds = thresholdMinutes * 60;
    
    return timeUntilExpiry <= thresholdSeconds;
  } catch (error) {
    return true; // Si hay error, asumir que necesita refresh
  }
};

module.exports = {
  generateTokenPair,
  verifyRefreshToken,
  isTokenNearExpiry
};
