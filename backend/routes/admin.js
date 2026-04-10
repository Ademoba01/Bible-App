const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const { parsePagination, paginatedResponse, sanitize, asyncHandler } = require('../utils/helpers');
const { getDb } = require('../db/connection');

const router = express.Router();

// All admin routes require authentication + admin role
router.use(authenticate);
router.use(authorize('admin'));

// ============================================================
// POST MANAGEMENT
// ============================================================

// GET /api/admin/posts — list posts with optional status filter
router.get(
  '/posts',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const { page, limit, offset } = parsePagination(req.query);
    const { status } = req.query;

    let where = 'WHERE 1=1';
    const params = [];

    if (status) {
      where += ' AND p.status = ?';
      params.push(status);
    }

    const countRow = db.prepare(`SELECT COUNT(*) as total FROM posts p ${where}`).get(...params);
    const total = countRow.total;

    const posts = db
      .prepare(
        `SELECT p.id, p.title, p.content, p.category, p.status, p.featured,
                p.likes_count, p.views_count, p.created_at, p.updated_at,
                u.display_name as author_name, u.email as author_email
         FROM posts p
         LEFT JOIN users u ON p.user_id = u.id
         ${where}
         ORDER BY p.created_at DESC
         LIMIT ? OFFSET ?`
      )
      .all(...params, limit, offset);

    res.json(paginatedResponse(posts, total, page, limit));
  })
);

// PUT /api/admin/posts/:id/approve — approve a post
router.put(
  '/posts/:id/approve',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const postId = parseInt(req.params.id);

    const post = db.prepare('SELECT * FROM posts WHERE id = ?').get(postId);
    if (!post) {
      return res.status(404).json({ error: 'Post not found.' });
    }

    db.prepare("UPDATE posts SET status = 'approved', updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(postId);

    res.json({ message: 'Post approved.', postId });
  })
);

// PUT /api/admin/posts/:id/reject — reject a post
router.put(
  '/posts/:id/reject',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const postId = parseInt(req.params.id);

    const post = db.prepare('SELECT * FROM posts WHERE id = ?').get(postId);
    if (!post) {
      return res.status(404).json({ error: 'Post not found.' });
    }

    db.prepare("UPDATE posts SET status = 'rejected', updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(postId);

    res.json({ message: 'Post rejected.', postId });
  })
);

// ============================================================
// HYMN MANAGEMENT
// ============================================================

// POST /api/admin/hymns — add a hymn
router.post(
  '/hymns',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const { number, title, author, year, lyrics, category, source } = req.body;

    if (!title || !lyrics) {
      return res.status(400).json({ error: 'title and lyrics are required.' });
    }

    const result = db
      .prepare(
        'INSERT INTO hymns (number, title, author, year, lyrics, category, source) VALUES (?, ?, ?, ?, ?, ?, ?)'
      )
      .run(
        number || null,
        sanitize(title, 200),
        sanitize(author || '', 200),
        year || null,
        sanitize(lyrics, 50000),
        sanitize(category || 'general', 50),
        sanitize(source || 'public_domain', 100)
      );

    const hymn = db.prepare('SELECT * FROM hymns WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json({ message: 'Hymn added.', hymn });
  })
);

// ============================================================
// STUDY MATERIAL MANAGEMENT
// ============================================================

// POST /api/admin/materials — add study material
router.post(
  '/materials',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const { title, author, source, category, date, bibleReading, memoryVerse, content } = req.body;

    if (!title || !source || !category || !content) {
      return res.status(400).json({ error: 'title, source, category, and content are required.' });
    }

    const validCategories = ['open_heavens', 'search_the_scriptures', 'daily_manna', 'general'];
    if (!validCategories.includes(category)) {
      return res.status(400).json({ error: `category must be one of: ${validCategories.join(', ')}` });
    }

    const result = db
      .prepare(
        `INSERT INTO study_materials (title, author, source, category, date, bible_reading, memory_verse, content, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'approved')`
      )
      .run(
        sanitize(title, 200),
        sanitize(author || '', 200),
        sanitize(source, 200),
        category,
        date || null,
        sanitize(bibleReading || '', 200),
        sanitize(memoryVerse || '', 500),
        sanitize(content, 50000)
      );

    const material = db.prepare('SELECT * FROM study_materials WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json({ message: 'Study material added.', material });
  })
);

// ============================================================
// USER MANAGEMENT
// ============================================================

// GET /api/admin/users — list all users
router.get(
  '/users',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const { page, limit, offset } = parsePagination(req.query);
    const { search } = req.query;

    let where = 'WHERE 1=1';
    const params = [];

    if (search) {
      where += ' AND (email LIKE ? OR display_name LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    const countRow = db.prepare(`SELECT COUNT(*) as total FROM users ${where}`).get(...params);
    const total = countRow.total;

    const users = db
      .prepare(
        `SELECT id, email, display_name, role, created_at, last_login
         FROM users ${where}
         ORDER BY created_at DESC
         LIMIT ? OFFSET ?`
      )
      .all(...params, limit, offset);

    res.json(paginatedResponse(users, total, page, limit));
  })
);

// PUT /api/admin/users/:id/role — change user role
router.put(
  '/users/:id/role',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const userId = parseInt(req.params.id);
    const { role } = req.body;

    const validRoles = ['user', 'admin', 'moderator'];
    if (!role || !validRoles.includes(role)) {
      return res.status(400).json({ error: `role must be one of: ${validRoles.join(', ')}` });
    }

    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    // Prevent demoting yourself
    if (userId === req.user.id && role !== 'admin') {
      return res.status(400).json({ error: 'You cannot change your own role.' });
    }

    db.prepare('UPDATE users SET role = ? WHERE id = ?').run(role, userId);

    res.json({ message: `User role updated to ${role}.`, userId, role });
  })
);

// ============================================================
// DASHBOARD STATS
// ============================================================

// GET /api/admin/stats — dashboard statistics
router.get(
  '/stats',
  asyncHandler(async (req, res) => {
    const db = getDb();

    const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get().count;
    const postCount = db.prepare('SELECT COUNT(*) as count FROM posts').get().count;
    const pendingPosts = db.prepare("SELECT COUNT(*) as count FROM posts WHERE status = 'pending'").get().count;
    const approvedPosts = db.prepare("SELECT COUNT(*) as count FROM posts WHERE status = 'approved'").get().count;
    const hymnCount = db.prepare('SELECT COUNT(*) as count FROM hymns').get().count;
    const materialCount = db.prepare('SELECT COUNT(*) as count FROM study_materials').get().count;
    const commentCount = db.prepare('SELECT COUNT(*) as count FROM comments').get().count;

    // Recent users (last 7 days)
    const recentUsers = db
      .prepare("SELECT COUNT(*) as count FROM users WHERE created_at >= datetime('now', '-7 days')")
      .get().count;

    // Most liked posts
    const topPosts = db
      .prepare(
        `SELECT p.id, p.title, p.likes_count, p.views_count, u.display_name as author_name
         FROM posts p
         LEFT JOIN users u ON p.user_id = u.id
         WHERE p.status = 'approved'
         ORDER BY p.likes_count DESC
         LIMIT 5`
      )
      .all();

    res.json({
      users: { total: userCount, recentSignups: recentUsers },
      posts: { total: postCount, pending: pendingPosts, approved: approvedPosts },
      hymns: hymnCount,
      studyMaterials: materialCount,
      comments: commentCount,
      topPosts,
    });
  })
);

module.exports = router;
