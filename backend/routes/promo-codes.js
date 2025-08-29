const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');

// Helper: map UI payload to DB columns + metadata
function mapPayloadToDb(body) {
  const {
    code,
    title,
    description,
    type, // UI type (e.g., percentageDiscount, fixedAmount, freeShipping)
    value,
    maxUses,
    maxUsesPerUser,
    minOrderValue,
    countries,
    startDate,
    endDate,
    isActive,
    status,
    requiresApproval,
    createdBy,
    createdByName,
    createdByCountry,
  } = body || {};

  // Map to columns
  const columns = {
    code: (code || '').toUpperCase(),
    description: description || null,
    discount_type: type === 'fixedAmount' ? 'fixed' : 'percent',
    discount_value: typeof value === 'number' ? value : (value ? parseFloat(value) : 0),
    max_uses: maxUses != null && maxUses !== '' ? parseInt(maxUses, 10) : null,
    per_user_limit: maxUsesPerUser != null && maxUsesPerUser !== '' ? parseInt(maxUsesPerUser, 10) : null,
    starts_at: startDate ? new Date(startDate) : null,
    expires_at: endDate ? new Date(endDate) : null,
    is_active: typeof isActive === 'boolean' ? isActive : (status === 'active'),
  };

  // Extra metadata
  const metadata = {
    title: title || null,
    ui_type: type || null,
    min_order_value: minOrderValue != null && minOrderValue !== '' ? (typeof minOrderValue === 'number' ? minOrderValue : parseFloat(minOrderValue)) : null,
    countries: Array.isArray(countries) ? countries.map(c => String(c).toUpperCase()) : undefined,
    status: status || 'pendingApproval',
    requiresApproval: !!requiresApproval,
    createdBy: createdBy || null,
    createdByName: createdByName || null,
    createdByCountry: createdByCountry || null,
  };

  return { columns, metadata };
}

function rowToApi(row) {
  const m = row.metadata || {};
  return {
    id: row.id,
    code: row.code,
    title: m.title || null,
    description: row.description,
    type: m.ui_type || (row.discount_type === 'fixed' ? 'fixedAmount' : 'percentageDiscount'),
    value: Number(row.discount_value || 0),
    maxUses: row.max_uses,
    maxUsesPerUser: row.per_user_limit,
    minOrderValue: m.min_order_value || null,
    countries: m.countries || [],
    startDate: row.starts_at,
    endDate: row.expires_at,
    isActive: !!row.is_active,
    status: m.status || (row.is_active ? 'active' : 'disabled'),
    requiresApproval: !!m.requiresApproval,
    createdBy: m.createdBy || null,
    createdByName: m.createdByName || null,
    createdByCountry: m.createdByCountry || null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// List promo codes (admin only); optional country filter
router.get('/', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { country } = req.query;
    const result = await db.query('SELECT * FROM promo_codes ORDER BY created_at DESC');
    let rows = result.rows;
    if (country) {
      const cc = String(country).toUpperCase();
      rows = rows.filter(r => {
        const m = r.metadata || {};
        const arr = Array.isArray(m.countries) ? m.countries.map(c => String(c).toUpperCase()) : [];
        // visible if global (no countries specified) or includes country
        return arr.length === 0 || arr.includes(cc);
      });
    }
    return res.json(rows.map(rowToApi));
  } catch (err) {
    console.error('GET /promo-codes error:', err);
    res.status(500).json({ error: 'Failed to list promo codes' });
  }
});

// Create promo code
router.post('/', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { columns, metadata } = mapPayloadToDb(req.body || {});

    // Enforce unique code (case-insensitive)
    const existing = await db.queryOne('SELECT id FROM promo_codes WHERE code = $1', [columns.code]);
    if (existing) {
      return res.status(400).json({ error: 'Promo code already exists' });
    }

    const row = await db.queryOne(
      `INSERT INTO promo_codes (code, description, discount_type, discount_value, max_uses, per_user_limit, starts_at, expires_at, is_active, metadata)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10::jsonb)
       RETURNING *`,
      [
        columns.code,
        columns.description,
        columns.discount_type,
        columns.discount_value,
        columns.max_uses,
        columns.per_user_limit,
        columns.starts_at,
        columns.expires_at,
        columns.is_active,
        JSON.stringify(metadata),
      ]
    );
    res.status(201).json(rowToApi(row));
  } catch (err) {
    console.error('POST /promo-codes error:', err);
    res.status(500).json({ error: 'Failed to create promo code' });
  }
});

// Update promo code
router.put('/:id', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const prev = await db.queryOne('SELECT * FROM promo_codes WHERE id=$1::uuid', [id]);
    if (!prev) return res.status(404).json({ error: 'Not found' });
    const { columns, metadata } = mapPayloadToDb(req.body || {});

    // Prevent code collision if changing code
    if (columns.code && columns.code !== prev.code) {
      const collision = await db.queryOne('SELECT id FROM promo_codes WHERE code=$1', [columns.code]);
      if (collision) return res.status(400).json({ error: 'Promo code with this code already exists' });
    }

    // Merge metadata
    const mergedMeta = { ...(prev.metadata || {}), ...metadata };

    const updated = await db.queryOne(
      `UPDATE promo_codes
         SET code=$1, description=$2, discount_type=$3, discount_value=$4, max_uses=$5, per_user_limit=$6,
             starts_at=$7, expires_at=$8, is_active=$9, metadata=$10::jsonb, updated_at=NOW()
       WHERE id=$11::uuid
       RETURNING *`,
      [
        columns.code || prev.code,
        columns.description !== undefined ? columns.description : prev.description,
        columns.discount_type || prev.discount_type,
        columns.discount_value !== undefined ? columns.discount_value : prev.discount_value,
        columns.max_uses !== undefined ? columns.max_uses : prev.max_uses,
        columns.per_user_limit !== undefined ? columns.per_user_limit : prev.per_user_limit,
        columns.starts_at !== undefined ? columns.starts_at : prev.starts_at,
        columns.expires_at !== undefined ? columns.expires_at : prev.expires_at,
        columns.is_active !== undefined ? columns.is_active : prev.is_active,
        JSON.stringify(mergedMeta),
        id,
      ]
    );
    res.json(rowToApi(updated));
  } catch (err) {
    console.error('PUT /promo-codes/:id error:', err);
    res.status(500).json({ error: 'Failed to update promo code' });
  }
});

// Update status (e.g., approve, reject, disable)
router.put('/:id/status', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { status, rejectionReason } = req.body || {};
    const prev = await db.queryOne('SELECT * FROM promo_codes WHERE id=$1::uuid', [id]);
    if (!prev) return res.status(404).json({ error: 'Not found' });

    const meta = { ...(prev.metadata || {}), status: status || (prev.metadata?.status), rejectionReason: rejectionReason || null };
    // Toggle active based on status
    let isActive = prev.is_active;
    if (status) {
      isActive = status === 'active';
    }

    const updated = await db.queryOne(
      `UPDATE promo_codes SET is_active=$1, metadata=$2::jsonb, updated_at=NOW() WHERE id=$3::uuid RETURNING *`,
      [isActive, JSON.stringify(meta), id]
    );
    res.json(rowToApi(updated));
  } catch (err) {
    console.error('PUT /promo-codes/:id/status error:', err);
    res.status(500).json({ error: 'Failed to update promo code status' });
  }
});

// Delete promo code
router.delete('/:id', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await db.queryOne('DELETE FROM promo_codes WHERE id=$1::uuid RETURNING *', [id]);
    if (!deleted) return res.status(404).json({ error: 'Not found' });
    res.json({ success: true });
  } catch (err) {
    console.error('DELETE /promo-codes/:id error:', err);
    res.status(500).json({ error: 'Failed to delete promo code' });
  }
});

module.exports = router;
