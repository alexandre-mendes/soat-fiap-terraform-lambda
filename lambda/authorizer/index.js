const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

exports.handler = async (event) => {
  try {
    const token = event.headers?.authorization?.replace('Bearer ', '');

    if (!token) {
      return {
        isAuthorized: false,
      };
    }

    const decoded = jwt.verify(token, JWT_SECRET);

    return {
      isAuthorized: true,
      context: {
        cpf: decoded.cpf,
        needs_registration: decoded.needs_registration || false,
      },
    };
  } catch (err) {
    console.error('Authorization failed:', err);
    return {
      isAuthorized: false,
    };
  }
};
