const express = require('express');
const { authenticate } = require('../middleware/auth');
const { asyncHandler } = require('../utils/helpers');
const { getDb } = require('../db/connection');

const router = express.Router();

// All sync routes require authentication
router.use(authenticate);

// GET /api/sync/all — get all user sync data
router.get(
  '/all',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const userId = req.user.id;

    const bookmarks = db.prepare('SELECT verse_id, created_at FROM bookmarks WHERE user_id = ?').all(userId);
    const highlights = db.prepare('SELECT verse_id, color_index, created_at FROM highlights WHERE user_id = ?').all(userId);
    const readingProgress = db.prepare('SELECT book, chapter, updated_at FROM reading_progress WHERE user_id = ?').get(userId);
    const notes = db.prepare('SELECT id, verse_id, title, content, created_at, updated_at FROM study_notes WHERE user_id = ? ORDER BY updated_at DESC').all(userId);
    const studyProgress = db.prepare('SELECT plan_id, completed_days, start_date, updated_at FROM study_progress WHERE user_id = ?').all(userId);

    // Parse completed_days JSON
    const parsedProgress = studyProgress.map((sp) => ({
      ...sp,
      completed_days: JSON.parse(sp.completed_days || '[]'),
    }));

    res.json({
      bookmarks,
      highlights,
      readingProgress: readingProgress || null,
      notes,
      studyProgress: parsedProgress,
    });
  })
);

// PUT /api/sync/bookmarks — upsert bookmarks array
router.put(
  '/bookmarks',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const userId = req.user.id;
    const { bookmarks } = req.body;

    if (!Array.isArray(bookmarks)) {
      return res.status(400).json({ error: 'bookmarks must be an array of verse IDs.' });
    }

    const upsert = db.prepare(
      'INSERT OR REPLACE INTO bookmarks (user_id, verse_id) VALUES (?, ?)'
    );
    const deleteStmt = db.prepare('DELETE FROM bookmarks WHERE user_id = ? AND verse_id NOT IN (' +
      bookmarks.map(() => '?').join(',') + ')');

    const transaction = db.transaction(() => {
      // Upsert all current bookmarks
      for (const verseId of bookmarks) {
        upsert.run(userId, verseId);
      }
      // Remove bookmarks not in the new list
      if (bookmarks.length > 0) {
        deleteStmt.run(userId, ...bookmarks);
      } else {
        db.prepare('DELETE FROM bookmarks WHERE user_id = ?').run(userId);
      }
    });

    transaction();

    const updated = db.prepare('SELECT verse_id, created_at FROM bookmarks WHERE user_id = ?').all(userId);
    res.json({ message: 'Bookmarks synced.', bookmarks: updated });
  })
);

// PUT /api/sync/highlights — upsert highlights map
router.put(
  '/highlights',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const userId = req.user.id;
    const { highlights } = req.body;

    if (!Array.isArray(highlights)) {
      return res.status(400).json({ error: 'highlights must be an array of {verseId, colorIndex} objects.' });
    }

    const upsert = db.prepare(
      'INSERT INTO highlights (user_id, verse_id, color_index) VALUES (?, ?, ?) ON CONFLICT(user_id, verse_id) DO UPDATE SET color_index = excluded.color_index'
    );

    const verseIds = highlights.map((h) => h.verseId);
    const deleteStmt = verseIds.length > 0
      ? db.prepare('DELETE FROM highlights WHERE user_id = ? AND verse_id NOT IN (' + verseIds.map(() => '?').join(',') + ')')
      : null;

    const transaction = db.transaction(() => {
      for (const h of highlights) {
        if (h.verseId) {
          upsert.run(userId, h.verseId, h.colorIndex || 0);
        }
      }
      if (verseIds.length > 0) {
        deleteStmt.run(userId, ...verseIds);
      } else {
        db.prepare('DELETE FROM highlights WHERE user_id = ?').run(userId);
      }
    });

    transaction();

    const updated = db.prepare('SELECT verse_id, color_index, created_at FROM highlights WHERE user_id = ?').all(userId);
    res.json({ message: 'Highlights synced.', highlights: updated });
  })
);

// PUT /api/sync/reading-position — update current reading position
router.put(
  '/reading-position',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const userId = req.user.id;
    const { book, chapter } = req.body;

    if (!book || chapter === undefined) {
      return res.status(400).json({ error: 'book and chapter are required.' });
    }

    db.prepare(
      'INSERT INTO reading_progress (user_id, book, chapter) VALUES (?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET book = excluded.book, chapter = excluded.chapter, updated_at = CURRENT_TIMESTAMP'
    ).run(userId, book, chapter);

    const updated = db.prepare('SELECT book, chapter, updated_at FROM reading_progress WHERE user_id = ?').get(userId);
    res.json({ message: 'Reading position updated.', readingProgress: updated });
  })
);

// PUT /api/sync/notes — upsert notes
router.put(
  '/notes',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const userId = req.user.id;
    const { notes } = req.body;

    if (!Array.isArray(notes)) {
      return res.status(400).json({ error: 'notes must be an array.' });
    }

    const upsert = db.prepare(
      `INSERT INTO study_notes (user_id, verse_id, title, content)
       VALUES (?, ?, ?, ?)
       ON CONFLICT DO NOTHING`
    );
    const update = db.prepare(
      `UPDATE study_notes SET verse_id = ?, title = ?, content = ?, updated_at = CURRENT_TIMESTAMP
       WHERE id = ? AND user_id = ?`
    );

    const transaction = db.transaction(() => {
      for (const note of notes) {
        if (note.id) {
          // Update existing note
          update.run(note.verseId || null, note.title, note.content, note.id, userId);
        } else {
          // Insert new note
          upsert.run(userId, note.verseId || null, note.title, note.content);
        }
      }
    });

    transaction();

    const updated = db.prepare(
      'SELECT id, verse_id, title, content, created_at, updated_at FROM study_notes WHERE user_id = ? ORDER BY updated_at DESC'
    ).all(userId);
    res.json({ message: 'Notes synced.', notes: updated });
  })
);

// PUT /api/sync/study-progress — upsert study progress
router.put(
  '/study-progress',
  asyncHandler(async (req, res) => {
    const db = getDb();
    const userId = req.user.id;
    const { studyProgress } = req.body;

    if (!Array.isArray(studyProgress)) {
      return res.status(400).json({ error: 'studyProgress must be an array.' });
    }

    const upsert = db.prepare(
      `INSERT INTO study_progress (user_id, plan_id, completed_days, start_date)
       VALUES (?, ?, ?, ?)
       ON CONFLICT(user_id, plan_id) DO UPDATE SET
         completed_days = excluded.completed_days,
         start_date = excluded.start_date,
         updated_at = CURRENT_TIMESTAMP`
    );

    const transaction = db.transaction(() => {
      for (const sp of studyProgress) {
        if (!sp.planId) continue;
        upsert.run(
          userId,
          sp.planId,
          JSON.stringify(sp.completedDays || []),
          sp.startDate || null
        );
      }
    });

    transaction();

    const updated = db.prepare('SELECT plan_id, completed_days, start_date, updated_at FROM study_progress WHERE user_id = ?').all(userId);
    const parsed = updated.map((sp) => ({
      ...sp,
      completed_days: JSON.parse(sp.completed_days || '[]'),
    }));
    res.json({ message: 'Study progress synced.', studyProgress: parsed });
  })
);

module.exports = router;
