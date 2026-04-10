/**
 * Parse pagination parameters from query string.
 * Returns { page, limit, offset } with safe defaults.
 */
function parsePagination(query, defaults = { page: 1, limit: 20 }) {
  const page = Math.max(1, parseInt(query.page) || defaults.page);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit) || defaults.limit));
  const offset = (page - 1) * limit;
  return { page, limit, offset };
}

/**
 * Format a paginated response with metadata.
 */
function paginatedResponse(data, total, page, limit) {
  return {
    data,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
      hasMore: page * limit < total,
    },
  };
}

/**
 * Sanitize a string for safe storage — trims and limits length.
 */
function sanitize(str, maxLength = 10000) {
  if (typeof str !== 'string') return '';
  return str.trim().slice(0, maxLength);
}

/**
 * Validate email format.
 */
function isValidEmail(email) {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
}

/**
 * Wrap an async route handler to catch errors automatically.
 */
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = {
  parsePagination,
  paginatedResponse,
  sanitize,
  isValidEmail,
  asyncHandler,
};
