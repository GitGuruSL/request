const db = require('./database');

async function ensureSchema() {
  try { await db.query('CREATE EXTENSION IF NOT EXISTS pgcrypto'); } catch (_) {}
  await db.query(`CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL,
    sender_id UUID,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    status TEXT DEFAULT 'unread',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
  );`);
  await db.query(`CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_id, created_at DESC);`);
  await db.query(`CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);`);
}

async function createNotification({ recipientId, senderId, type, title, message, data }) {
  await ensureSchema();
  return db.queryOne(
    `INSERT INTO notifications (recipient_id, sender_id, type, title, message, data)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [recipientId, senderId || null, String(type), title, message, data ? JSON.stringify(data) : null]
  );
}

async function markAsRead(id) {
  await ensureSchema();
  return db.queryOne(`UPDATE notifications SET status='read', read_at=NOW() WHERE id=$1 RETURNING *`, [id]);
}

async function markAllAsRead(userId) {
  await ensureSchema();
  await db.query(`UPDATE notifications SET status='read', read_at=NOW() WHERE recipient_id=$1 AND status='unread'`, [userId]);
}

async function listForUser(userId, { limit = 200, offset = 0 } = {}) {
  await ensureSchema();
  const rows = await db.query(`SELECT * FROM notifications WHERE recipient_id=$1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`, [userId, limit, offset]);
  return rows.rows;
}

async function remove(id) {
  await ensureSchema();
  return db.queryOne(`DELETE FROM notifications WHERE id=$1 RETURNING *`, [id]);
}

module.exports = {
  ensureSchema,
  createNotification,
  markAsRead,
  markAllAsRead,
  listForUser,
  remove,
};
