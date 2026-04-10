/**
 * Shared database connection module.
 * Holds reference to the SQLite database instance.
 */
let db = null;

function setDb(database) {
  db = database;
}

function getDb() {
  if (!db) {
    throw new Error('Database not initialized. Call setDb() first.');
  }
  return db;
}

module.exports = { setDb, getDb };
