const express = require('express');
const router = express.Router();
// database.js exports a singleton instance already
const db = require('../services/database');

async function ensureSchema() {
  // Enable pgcrypto for gen_random_uuid (ignore error if not permitted)
  try { await db.query('CREATE EXTENSION IF NOT EXISTS pgcrypto'); } catch (_) {}
  await db.query(`CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL,
    participant_a UUID NOT NULL,
    participant_b UUID NOT NULL,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(request_id, participant_a, participant_b)
  );`);
  await db.query(`CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );`);
}

function canonicalPair(a, b) { return a < b ? [a, b] : [b, a]; }

router.post('/open', async (req, res) => {
  try {
    const { requestId, currentUserId, otherUserId } = req.body;
    if (!requestId || !currentUserId || !otherUserId) {
      return res.status(400).json({ success: false, error: 'requestId, currentUserId, otherUserId required' });
    }
    await ensureSchema();
    const [a, b] = canonicalPair(currentUserId, otherUserId);
    let convo = await db.queryOne(`SELECT * FROM conversations WHERE request_id=$1 AND participant_a=$2 AND participant_b=$3`, [requestId, a, b]);
    if (!convo) {
      convo = await db.queryOne(`INSERT INTO conversations (request_id, participant_a, participant_b) VALUES ($1,$2,$3) RETURNING *`, [requestId, a, b]);
    }
    const messages = await db.query(`SELECT * FROM messages WHERE conversation_id=$1 ORDER BY created_at ASC LIMIT 100`, [convo.id]);
    const requestRow = await db.queryOne(`SELECT title FROM requests WHERE id=$1`, [requestId]);
    res.json({ success: true, conversation: { ...convo, requestTitle: requestRow?.title }, messages: messages.rows });
  } catch (e) {
    console.error('Chat open error', e);
    res.status(500).json({ success: false, error: 'Failed to open conversation' });
  }
});

router.get('/conversations', async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ success: false, error: 'userId required' });
    await ensureSchema();
    const rows = await db.query(`SELECT c.*, r.title AS request_title FROM conversations c JOIN requests r ON r.id = c.request_id WHERE participant_a=$1 OR participant_b=$1 ORDER BY last_message_at DESC LIMIT 200`, [userId]);
    res.json({ success: true, conversations: rows.rows });
  } catch (e) {
    console.error('Chat list error', e);
    res.status(500).json({ success: false, error: 'Failed to list conversations' });
  }
});

router.get('/messages/:conversationId', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const rows = await db.query(`SELECT * FROM messages WHERE conversation_id=$1 ORDER BY created_at ASC LIMIT 500`, [conversationId]);
    res.json({ success: true, messages: rows.rows });
  } catch (e) {
    console.error('Chat messages error', e);
    res.status(500).json({ success: false, error: 'Failed to fetch messages' });
  }
});

router.post('/messages', async (req, res) => {
  try {
    const { conversationId, senderId, content } = req.body;
    if (!conversationId || !senderId || !content) {
      return res.status(400).json({ success: false, error: 'conversationId, senderId, content required' });
    }
    const convo = await db.queryOne(`SELECT * FROM conversations WHERE id=$1`, [conversationId]);
    if (!convo) return res.status(404).json({ success: false, error: 'Conversation not found' });
    const msg = await db.queryOne(`INSERT INTO messages (conversation_id, sender_id, content) VALUES ($1,$2,$3) RETURNING *`, [conversationId, senderId, content]);
    await db.query(`UPDATE conversations SET last_message_text=$1, last_message_at=NOW() WHERE id=$2`, [content.substring(0, 500), conversationId]);
    res.json({ success: true, message: msg });
  } catch (e) {
    console.error('Chat send error', e);
    res.status(500).json({ success: false, error: 'Failed to send message' });
  }
});

module.exports = router;
