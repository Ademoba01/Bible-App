const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { authenticate } = require('../middleware/auth');
const { isValidEmail, sanitize, asyncHandler } = require('../utils/helpers');
const { getDb } = require('../db/connection');

const router = express.Router();

/**
 * Generate access + refresh tokens for a user.
 */
function generateTokens(user) {
  const accessToken = jwt.sign(
    { id: user.id, email: user.email, role: user.role, displayName: user.display_name },
    process.env.JWT_SECRET,
    { expiresIn: '24h' }
  );

  const refreshToken = uuidv4();
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(); // 30 days

  const db = getDb();
  db.prepare('INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (?, ?, ?)').run(
    user.id,
    refreshToken,
    expiresAt
  );

  return { accessToken, refreshToken };
}

// POST /api/auth/register
router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const { email, password, displayName } = req.body;

    if (!email || !password || !displayName) {
      return res.status(400).json({ error: 'Email, password, and displayName are required.' });
    }

    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format.' });
    }

    if (password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters.' });
    }

    const db = getDb();
    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase());
    if (existing) {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const result = db.prepare(
      'INSERT INTO users (email, password_hash, display_name) VALUES (?, ?, ?)'
    ).run(email.toLowerCase(), passwordHash, sanitize(displayName, 100));

    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(result.lastInsertRowid);
    const tokens = generateTokens(user);

    res.status(201).json({
      message: 'Account created successfully.',
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        role: user.role,
      },
      ...tokens,
    });
  })
);

// POST /api/auth/login
router.post(
  '/login',
  asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    const db = getDb();
    const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email.toLowerCase());

    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    // Update last login
    db.prepare('UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?').run(user.id);

    const tokens = generateTokens(user);

    res.json({
      message: 'Login successful.',
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        role: user.role,
      },
      ...tokens,
    });
  })
);

// POST /api/auth/refresh
router.post(
  '/refresh',
  asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required.' });
    }

    const db = getDb();
    const stored = db
      .prepare('SELECT * FROM refresh_tokens WHERE token = ?')
      .get(refreshToken);

    if (!stored) {
      return res.status(401).json({ error: 'Invalid refresh token.' });
    }

    if (new Date(stored.expires_at) < new Date()) {
      db.prepare('DELETE FROM refresh_tokens WHERE id = ?').run(stored.id);
      return res.status(401).json({ error: 'Refresh token expired. Please log in again.' });
    }

    // Delete the used refresh token (rotation)
    db.prepare('DELETE FROM refresh_tokens WHERE id = ?').run(stored.id);

    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(stored.user_id);
    if (!user) {
      return res.status(401).json({ error: 'User not found.' });
    }

    const tokens = generateTokens(user);

    res.json({
      message: 'Token refreshed.',
      ...tokens,
    });
  })
);

// GET /api/auth/me
router.get(
  '/me',
  authenticate,
  asyncHandler(async (req, res) => {
    const db = getDb();
    const user = db.prepare('SELECT id, email, display_name, role, created_at, last_login FROM users WHERE id = ?').get(req.user.id);

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    res.json({
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        role: user.role,
        createdAt: user.created_at,
        lastLogin: user.last_login,
      },
    });
  })
);

module.exports = router;
