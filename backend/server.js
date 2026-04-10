require('dotenv').config();

const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const path = require('path');
const fs = require('fs');
const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const { setDb } = require('./db/connection');

const app = express();

// ============================================================
// DATABASE SETUP
// ============================================================

function initDatabase() {
  const dbPath = path.resolve(process.env.DB_PATH || './db/bible_app.db');
  const dbDir = path.dirname(dbPath);

  // Ensure the db directory exists
  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
  }

  const isNew = !fs.existsSync(dbPath);
  const db = new Database(dbPath);

  // Register with shared connection module
  setDb(db);

  // Enable WAL mode for better performance
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');

  // Run schema (uses IF NOT EXISTS so safe to run on existing DB)
  const schemaPath = path.join(__dirname, 'db', 'schema.sql');
  const schema = fs.readFileSync(schemaPath, 'utf-8');
  db.exec(schema);

  if (isNew) {
    console.log('[DB] New database created. Running seed data...');

    // Run seed SQL
    const seedPath = path.join(__dirname, 'db', 'seed.sql');
    const seed = fs.readFileSync(seedPath, 'utf-8');
    db.exec(seed);

    // Create admin user with bcrypt hash
    const adminEmail = 'admin@ourbible.app';
    const adminPassword = 'OurBible2024!';
    const adminHash = bcrypt.hashSync(adminPassword, 12);

    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(adminEmail);
    if (!existing) {
      db.prepare(
        "INSERT INTO users (email, password_hash, display_name, role) VALUES (?, ?, ?, 'admin')"
      ).run(adminEmail, adminHash, 'Admin');
      console.log('[DB] Admin user created: admin@ourbible.app');
    }

    console.log('[DB] Seed data loaded successfully.');
  } else {
    console.log('[DB] Existing database loaded.');
  }

  return db;
}

// ============================================================
// MIDDLEWARE
// ============================================================

// CORS
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || 'http://localhost:8765',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// JSON body parser with 10mb limit for large sync payloads
app.use(express.json({ limit: '10mb' }));

// Rate limiting: 100 requests per 15 minutes per IP
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests. Please try again later.' },
});
app.use('/api/', limiter);

// Request logging
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(
      `[${new Date().toISOString()}] ${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`
    );
  });
  next();
});

// ============================================================
// ROUTES
// ============================================================

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Mount route files
app.use('/api/auth', require('./routes/auth'));
app.use('/api/sync', require('./routes/sync'));
app.use('/api/community', require('./routes/community'));
app.use('/api/admin', require('./routes/admin'));

// Serve admin dashboard static files
app.use('/admin', express.static(path.join(__dirname, 'admin')));

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found.' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(`[ERROR] ${err.stack || err.message}`);
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal server error.' : err.message,
  });
});

// ============================================================
// START SERVER
// ============================================================

const PORT = parseInt(process.env.PORT) || 3001;

// Initialize DB before starting
initDatabase();

app.listen(PORT, () => {
  console.log(`\n  Our Bible API Server`);
  console.log(`  ====================`);
  console.log(`  Port:    ${PORT}`);
  console.log(`  CORS:    ${process.env.CORS_ORIGIN || 'http://localhost:8765'}`);
  console.log(`  DB:      ${process.env.DB_PATH || './db/bible_app.db'}`);
  console.log(`  Health:  http://localhost:${PORT}/api/health`);
  console.log(`  ====================\n`);
});
