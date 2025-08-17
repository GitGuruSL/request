const express = require('express');
const router = express.Router({ mergeParams: true });
const db = require('../services/database');
const auth = require('../services/auth');

// List responses for a request with pagination
router.get('/', async (req, res) => {
  try {
    const requestId = req.params.requestId;
    const { page = 1, limit = 20 } = req.query;
    const pageNum = parseInt(page) || 1;
    const lim = Math.min(parseInt(limit) || 20, 100);
    const offset = (pageNum - 1) * lim;

    // Verify request exists (cheap check)
    const exists = await db.queryOne('SELECT id FROM requests WHERE id = $1', [requestId]);
    if (!exists) {
      return res.status(404).json({ success: false, message: 'Request not found' });
    }

    const rows = await db.query(`
      SELECT r.*, u.display_name as user_name
      FROM responses r
      LEFT JOIN users u ON r.user_id = u.id
      WHERE r.request_id = $1
      ORDER BY r.created_at DESC
      LIMIT $2 OFFSET $3
    `, [requestId, lim, offset]);

    const countRow = await db.queryOne('SELECT COUNT(*)::int AS total FROM responses WHERE request_id = $1', [requestId]);

    res.json({
      success: true,
      data: {
        responses: rows.rows,
        pagination: {
          page: pageNum,
            limit: lim,
            total: countRow.total,
            totalPages: Math.ceil(countRow.total / lim)
        }
      }
    });
  } catch (error) {
    console.error('Error listing responses:', error);
    res.status(500).json({ success: false, message: 'Error listing responses', error: error.message });
  }
});

// Create a response (one per user per request enforced by unique index)
router.post('/', auth.authMiddleware(), async (req, res) => {
  try {
    const requestId = req.params.requestId;
    const userId = req.user.userId;
    const { message, price, currency, metadata, image_urls } = req.body;

    if (!message || message.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Message is required' });
    }

    // Ensure request is active and not owned by responding user
    const request = await db.queryOne('SELECT id, user_id, status, currency FROM requests WHERE id = $1', [requestId]);
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });
    if (request.user_id === userId) return res.status(400).json({ success: false, message: 'Cannot respond to your own request' });
    if (request.status !== 'active') return res.status(400).json({ success: false, message: 'Request not active' });

    const insert = await db.queryOne(`
      INSERT INTO responses (request_id, user_id, message, price, currency, metadata, image_urls)
      VALUES ($1,$2,$3,$4,$5,$6,$7)
      RETURNING *
    `, [requestId, userId, message.trim(), price ?? null, currency || request.currency, metadata || null, image_urls || null]);

    res.status(201).json({ success: true, message: 'Response created', data: insert });
  } catch (error) {
    if (error.code === '23505') { // unique violation
      return res.status(400).json({ success: false, message: 'You have already responded to this request' });
    }
    console.error('Error creating response:', error);
    res.status(500).json({ success: false, message: 'Error creating response', error: error.message });
  }
});

// Update a response (only owner)
router.put('/:responseId', auth.authMiddleware(), async (req, res) => {
  try {
    const { requestId, responseId } = req.params;
    const userId = req.user.userId;
    const { message, price, status } = req.body;

    const existing = await db.queryOne('SELECT * FROM responses WHERE id = $1 AND request_id = $2', [responseId, requestId]);
    if (!existing) return res.status(404).json({ success: false, message: 'Response not found' });
    if (existing.user_id !== userId) return res.status(403).json({ success: false, message: 'Not permitted' });
    // If this response is accepted, disallow edits except maybe price? For now block entirely
    const reqRow = await db.queryOne('SELECT accepted_response_id FROM requests WHERE id=$1', [requestId]);
    if (reqRow && reqRow.accepted_response_id === responseId) {
      return res.status(400).json({ success: false, message: 'Cannot edit an accepted response' });
    }

    const updates = [];
    const values = [];
    let p = 1;
    if (message !== undefined) { updates.push(`message = $${p++}`); values.push(message); }
    if (price !== undefined) { updates.push(`price = $${p++}`); values.push(price); }
    if (status !== undefined) { updates.push(`status = $${p++}`); values.push(status); }
    if (updates.length === 0) return res.status(400).json({ success: false, message: 'No fields to update' });
    values.push(responseId, requestId);

    const updated = await db.queryOne(`
      UPDATE responses SET ${updates.join(', ')}, updated_at = NOW()
      WHERE id = $${p++} AND request_id = $${p}
      RETURNING *
    `, values);

    res.json({ success: true, message: 'Response updated', data: updated });
  } catch (error) {
    console.error('Error updating response:', error);
    res.status(500).json({ success: false, message: 'Error updating response', error: error.message });
  }
});

// Delete a response (owner or request owner)
router.delete('/:responseId', auth.authMiddleware(), async (req, res) => {
  try {
    const { requestId, responseId } = req.params;
    const userId = req.user.userId;

    const existing = await db.queryOne('SELECT r.*, req.user_id as request_owner FROM responses r JOIN requests req ON r.request_id = req.id WHERE r.id = $1 AND r.request_id = $2', [responseId, requestId]);
    if (!existing) return res.status(404).json({ success: false, message: 'Response not found' });
    if (existing.user_id !== userId && existing.request_owner !== userId) return res.status(403).json({ success: false, message: 'Not permitted' });

    // Prevent deleting an accepted response by non-request-owner; only request owner can clear via unaccept then delete.
    const reqRow = await db.queryOne('SELECT accepted_response_id FROM requests WHERE id=$1', [requestId]);
    if (reqRow && reqRow.accepted_response_id === responseId && existing.request_owner !== userId) {
      return res.status(400).json({ success: false, message: 'Accepted response cannot be deleted (owner must unaccept first)' });
    }
    const deleted = await db.queryOne('DELETE FROM responses WHERE id = $1 RETURNING *', [responseId]);
    res.json({ success: true, message: 'Response deleted', data: deleted });
  } catch (error) {
    console.error('Error deleting response:', error);
    res.status(500).json({ success: false, message: 'Error deleting response', error: error.message });
  }
});

module.exports = router;
