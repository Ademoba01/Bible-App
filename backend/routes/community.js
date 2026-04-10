const express = require('express');
const { authenticate } = require('../middleware/auth');
const { parsePagination, paginatedResponse, sanitize, asyncHandler } = require('../utils/helpers');
const { getDb } = require('../db/connection');

const router = express.Router();

// ============================================================
// POSTS
// ============================================================

// GET /api/community/posts — list approved posts with pagination
router.get(
  '/posts',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const { page, limit, offset } = parsePagination(req.query);
    const { category, search } = req.query;

    let where = 'WHERE p.status = ?';
    const params = ['approved'];

    if (category) {
      where += ' AND p.category = ?';
      params.push(category);
    }

    if (search) {
      where += ' AND (p.title LIKE ? OR p.content LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    const countRow = db.prepare(`SELECT COUNT(*) as total FROM posts p ${where}`).get(...params);
    const total = countRow.total;

    const posts = db
      .prepare(
        `SELECT p.id, p.title, p.content, p.category, p.featured, p.likes_count, p.views_count,
                p.created_at, p.updated_at, u.display_name as author_name
         FROM posts p
         LEFT JOIN users u ON p.user_id = u.id
         ${where}
         ORDER BY p.featured DESC, p.created_at DESC
         LIMIT ? OFFSET ?`
      )
      .all(...params, limit, offset);

    // Attach tags to each post
    const tagStmt = db.prepare('SELECT tag FROM post_tags WHERE post_id = ?');
    const postsWithTags = posts.map((post) => ({
      ...post,
      tags: tagStmt.all(post.id).map((t) => t.tag),
    }));

    res.json(paginatedResponse(postsWithTags, total, page, limit));
  })
);

// GET /api/community/posts/:id — single post with comments
router.get(
  '/posts/:id',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const postId = parseInt(req.params.id);

    const post = db
      .prepare(
        `SELECT p.*, u.display_name as author_name
         FROM posts p
         LEFT JOIN users u ON p.user_id = u.id
         WHERE p.id = ? AND p.status = 'approved'`
      )
      .get(postId);

    if (!post) {
      return res.status(404).json({ error: 'Post not found.' });
    }

    // Increment views
    db.prepare('UPDATE posts SET views_count = views_count + 1 WHERE id = ?').run(postId);

    const tags = db.prepare('SELECT tag FROM post_tags WHERE post_id = ?').all(postId).map((t) => t.tag);

    const comments = db
      .prepare(
        `SELECT c.id, c.content, c.created_at, u.display_name as author_name
         FROM comments c
         LEFT JOIN users u ON c.user_id = u.id
         WHERE c.post_id = ?
         ORDER BY c.created_at ASC`
      )
      .all(postId);

    res.json({
      ...post,
      views_count: post.views_count + 1,
      tags,
      comments,
    });
  })
);

// POST /api/community/posts — create post (protected, pending approval)
router.post(
  '/posts',
  authenticate,
  asyncHandler(async (req, res) => {
    const db = getDb();
    const { title, content, category, tags } = req.body;

    if (!title || !content || !category) {
      return res.status(400).json({ error: 'title, content, and category are required.' });
    }

    const validCategories = ['study_material', 'devotional', 'testimony', 'hymn', 'discussion'];
    if (!validCategories.includes(category)) {
      return res.status(400).json({ error: `category must be one of: ${validCategories.join(', ')}` });
    }

    // Admins get auto-approved
    const status = req.user.role === 'admin' ? 'approved' : 'pending';

    const result = db
      .prepare('INSERT INTO posts (user_id, title, content, category, status) VALUES (?, ?, ?, ?, ?)')
      .run(req.user.id, sanitize(title, 200), sanitize(content), category, status);

    // Insert tags if provided
    if (Array.isArray(tags) && tags.length > 0) {
      const tagStmt = db.prepare('INSERT OR IGNORE INTO post_tags (post_id, tag) VALUES (?, ?)');
      for (const tag of tags.slice(0, 10)) {
        tagStmt.run(result.lastInsertRowid, sanitize(tag, 50).toLowerCase());
      }
    }

    const post = db.prepare('SELECT * FROM posts WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json({ message: 'Post created. It will be visible after admin approval.', post });
  })
);

// POST /api/community/posts/:id/like — toggle like
router.post(
  '/posts/:id/like',
  authenticate,
  asyncHandler(async (req, res) => {
    const db = getDb();
    const postId = parseInt(req.params.id);
    const userId = req.user.id;

    const post = db.prepare("SELECT id FROM posts WHERE id = ? AND status = 'approved'").get(postId);
    if (!post) {
      return res.status(404).json({ error: 'Post not found.' });
    }

    const existing = db.prepare('SELECT * FROM post_likes WHERE user_id = ? AND post_id = ?').get(userId, postId);

    if (existing) {
      db.prepare('DELETE FROM post_likes WHERE user_id = ? AND post_id = ?').run(userId, postId);
      db.prepare('UPDATE posts SET likes_count = MAX(0, likes_count - 1) WHERE id = ?').run(postId);
      return res.json({ message: 'Like removed.', liked: false });
    } else {
      db.prepare('INSERT INTO post_likes (user_id, post_id) VALUES (?, ?)').run(userId, postId);
      db.prepare('UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?').run(postId);
      return res.json({ message: 'Post liked.', liked: true });
    }
  })
);

// POST /api/community/posts/:id/comments — add comment
router.post(
  '/posts/:id/comments',
  authenticate,
  asyncHandler(async (req, res) => {
    const db = getDb();
    const postId = parseInt(req.params.id);
    const { content } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Comment content is required.' });
    }

    const post = db.prepare("SELECT id FROM posts WHERE id = ? AND status = 'approved'").get(postId);
    if (!post) {
      return res.status(404).json({ error: 'Post not found.' });
    }

    const result = db
      .prepare('INSERT INTO comments (post_id, user_id, content) VALUES (?, ?, ?)')
      .run(postId, req.user.id, sanitize(content, 5000));

    const comment = db
      .prepare(
        `SELECT c.id, c.content, c.created_at, u.display_name as author_name
         FROM comments c
         LEFT JOIN users u ON c.user_id = u.id
         WHERE c.id = ?`
      )
      .get(result.lastInsertRowid);

    res.status(201).json({ message: 'Comment added.', comment });
  })
);

// ============================================================
// HYMNS
// ============================================================

// GET /api/community/hymns — list hymns with search and pagination
router.get(
  '/hymns',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const { page, limit, offset } = parsePagination(req.query);
    const { search, category } = req.query;

    let where = 'WHERE 1=1';
    const params = [];

    if (search) {
      where += ' AND (title LIKE ? OR author LIKE ? OR lyrics LIKE ?)';
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    if (category) {
      where += ' AND category = ?';
      params.push(category);
    }

    const countRow = db.prepare(`SELECT COUNT(*) as total FROM hymns ${where}`).get(...params);
    const total = countRow.total;

    const hymns = db
      .prepare(
        `SELECT id, number, title, author, year, category, source
         FROM hymns ${where}
         ORDER BY number ASC
         LIMIT ? OFFSET ?`
      )
      .all(...params, limit, offset);

    res.json(paginatedResponse(hymns, total, page, limit));
  })
);

// GET /api/community/hymns/:id — single hymn
router.get(
  '/hymns/:id',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const hymn = db.prepare('SELECT * FROM hymns WHERE id = ?').get(parseInt(req.params.id));

    if (!hymn) {
      return res.status(404).json({ error: 'Hymn not found.' });
    }

    res.json(hymn);
  })
);

// ============================================================
// STUDY MATERIALS
// ============================================================

// GET /api/community/materials — list study materials
router.get(
  '/materials',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const { page, limit, offset } = parsePagination(req.query);
    const { category, date, search } = req.query;

    let where = "WHERE status = 'approved'";
    const params = [];

    if (category) {
      where += ' AND category = ?';
      params.push(category);
    }

    if (date) {
      where += ' AND date = ?';
      params.push(date);
    }

    if (search) {
      where += ' AND (title LIKE ? OR content LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    const countRow = db.prepare(`SELECT COUNT(*) as total FROM study_materials ${where}`).get(...params);
    const total = countRow.total;

    const materials = db
      .prepare(
        `SELECT id, title, author, source, category, date, bible_reading, memory_verse, created_at
         FROM study_materials ${where}
         ORDER BY date DESC, created_at DESC
         LIMIT ? OFFSET ?`
      )
      .all(...params, limit, offset);

    res.json(paginatedResponse(materials, total, page, limit));
  })
);

// GET /api/community/materials/:id — single study material
router.get(
  '/materials/:id',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const material = db.prepare("SELECT * FROM study_materials WHERE id = ? AND status = 'approved'").get(parseInt(req.params.id));

    if (!material) {
      return res.status(404).json({ error: 'Study material not found.' });
    }

    res.json(material);
  })
);

module.exports = router;
