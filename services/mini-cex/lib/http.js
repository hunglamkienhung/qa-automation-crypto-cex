'use strict';

const crypto = require('crypto');

/**
 * Cross-cutting HTTP helpers: one error shape and a token minter. Small
 * explicit functions the routes call, so what a route does is visible at the
 * route.
 */

class ApiError extends Error {
  constructor(status, code, message, extra = {}) {
    super(message);
    this.status = status;
    this.code = code;
    this.extra = extra;
  }
}

function errorBody(err) {
  return { error: err.message, code: err.code, ...err.extra };
}

function token(prefix) {
  return prefix + '_' + crypto.randomBytes(18).toString('base64url');
}

module.exports = { ApiError, errorBody, token };
