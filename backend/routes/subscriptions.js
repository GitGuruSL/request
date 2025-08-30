const express = require('express');
const router = express.Router();
const database = require('../services/database');
const auth = require('../services/auth');

function isSuperAdmin(user) {
  return user && (user.role === 'super_admin' || (user.roles && user.roles.includes('super_admin')));
}

function isCountryAdmin(user) {
  return user && (user.role === 'country_admin' || (user.roles && user.roles.includes('country_admin')));
}

// Get all global plans (super admin view)
router.get('/plans', auth.authMiddleware(), async (req, res) => {
  try {
    if (!isSuperAdmin(req.user)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
  const result = await database.query('SELECT * FROM subscription_plans ORDER BY id');
  res.json(result.rows);
  } catch (err) {
    console.error('GET /plans error', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// Create or update a global plan (super admin)
router.post('/plans', auth.authMiddleware(), async (req, res) => {
  try {
    if (!isSuperAdmin(req.user)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const { code, name, description, plan_type, default_responses_per_month } = req.body;
    if (!code || !name || !plan_type) return res.status(400).json({ error: 'Missing fields' });
  const upsert = await database.query(
      `INSERT INTO subscription_plans (code, name, description, plan_type, default_responses_per_month)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description, plan_type=EXCLUDED.plan_type, default_responses_per_month=EXCLUDED.default_responses_per_month
       RETURNING *`,
      [code, name, description || null, plan_type, default_responses_per_month || null]
    );
    res.json(upsert.rows[0]);
  } catch (err) {
    console.error('POST /plans error', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// Approve plan (super admin)
router.post('/plans/:code/approve', auth.authMiddleware(), async (req, res) => {
  try {
    if (!isSuperAdmin(req.user)) return res.status(403).json({ error: 'Forbidden' });
    const { code } = req.params;
  const { rows } = await database.query(
      `UPDATE subscription_plans SET status='active', approved_by=$1, approved_at=NOW() WHERE code=$2 RETURNING *`,
      [req.user?.email || req.user?.id || 'system', code]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error('POST /plans/:code/approve error', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// Country settings list or upsert (country admin)
router.get('/country-settings', auth.authMiddleware(), async (req, res) => {
  try {
    if (!isCountryAdmin(req.user) && !isSuperAdmin(req.user)) return res.status(403).json({ error: 'Forbidden' });
    const { country_code } = req.query;
    if (!country_code) return res.status(400).json({ error: 'country_code required' });
  const { rows } = await database.query(`
      SELECT scs.*, sp.code as plan_code, sp.name as plan_name, sp.plan_type
      FROM subscription_country_settings scs
      JOIN subscription_plans sp ON sp.id = scs.plan_id
      WHERE scs.country_code = $1
      ORDER BY scs.id
    `, [country_code]);
    res.json(rows);
  } catch (err) {
    console.error('GET /country-settings error', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

router.post('/country-settings', auth.authMiddleware(), async (req, res) => {
  try {
    if (!isCountryAdmin(req.user) && !isSuperAdmin(req.user)) return res.status(403).json({ error: 'Forbidden' });
    const { country_code, plan_code, currency, price, responses_per_month, ppc_price, is_active } = req.body;
    if (!country_code || !plan_code || !currency) return res.status(400).json({ error: 'Missing fields' });
  const plan = await database.query('SELECT id FROM subscription_plans WHERE code=$1', [plan_code]);
    if (!plan.rows[0]) return res.status(404).json({ error: 'Plan not found' });
    const planId = plan.rows[0].id;
  const upsert = await database.query(`
      INSERT INTO subscription_country_settings (plan_id, country_code, currency, price, responses_per_month, ppc_price, is_active, created_by, updated_by)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$8)
      ON CONFLICT (plan_id, country_code)
      DO UPDATE SET currency=EXCLUDED.currency, price=EXCLUDED.price, responses_per_month=EXCLUDED.responses_per_month, ppc_price=EXCLUDED.ppc_price, is_active=EXCLUDED.is_active, updated_by=EXCLUDED.updated_by
      RETURNING *
    `, [planId, country_code, currency, price || null, responses_per_month || null, ppc_price || null, !!is_active, req.user?.email || req.user?.id || 'system']);
    res.json(upsert.rows[0]);
  } catch (err) {
    console.error('POST /country-settings error', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// Map plans to business types and allowed request types
router.get('/mappings', auth.authMiddleware(), async (req, res) => {
  try {
    if (!isCountryAdmin(req.user) && !isSuperAdmin(req.user)) return res.status(403).json({ error: 'Forbidden' });
    const { country_code } = req.query;
    if (!country_code) return res.status(400).json({ error: 'country_code required' });
  const { rows } = await database.query(`
      SELECT m.*, bt.name as business_type_name, sp.code as plan_code,
             ARRAY(SELECT request_type FROM business_type_plan_allowed_request_types ar WHERE ar.mapping_id = m.id AND ar.is_active = TRUE) as allowed_request_types
      FROM business_type_plan_mappings m
      JOIN business_types bt ON bt.id = m.business_type_id
      JOIN subscription_plans sp ON sp.id = m.plan_id
      WHERE m.country_code = $1
      ORDER BY m.id
    `, [country_code]);
    res.json(rows);
  } catch (err) {
    console.error('GET /mappings error', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

router.post('/mappings', auth.authMiddleware(), async (req, res) => {
  const client = await database.getClient();
  try {
    if (!isCountryAdmin(req.user) && !isSuperAdmin(req.user)) return res.status(403).json({ error: 'Forbidden' });
    const { country_code, business_type_id, plan_code, allowed_request_types, is_active } = req.body;
    if (!country_code || !business_type_id || !plan_code) return res.status(400).json({ error: 'Missing fields' });
  const plan = await client.query('SELECT id FROM subscription_plans WHERE code=$1', [plan_code]);
    if (!plan.rows[0]) return res.status(404).json({ error: 'Plan not found' });
    await client.query('BEGIN');
    const upsert = await client.query(`
      INSERT INTO business_type_plan_mappings (country_code, business_type_id, plan_id, is_active)
      VALUES ($1,$2,$3,$4)
      ON CONFLICT (country_code, business_type_id, plan_id)
      DO UPDATE SET is_active=EXCLUDED.is_active
      RETURNING *
    `, [country_code, business_type_id, plan.rows[0].id, is_active !== false]);
    const mappingId = upsert.rows[0].id;
    if (Array.isArray(allowed_request_types)) {
      // Replace existing set
      await client.query('DELETE FROM business_type_plan_allowed_request_types WHERE mapping_id=$1', [mappingId]);
      for (const rt of allowed_request_types) {
        await client.query(
          `INSERT INTO business_type_plan_allowed_request_types (mapping_id, request_type, is_active) VALUES ($1,$2,TRUE)
           ON CONFLICT (mapping_id, request_type) DO UPDATE SET is_active=EXCLUDED.is_active`,
          [mappingId, rt]
        );
      }
    }
    await client.query('COMMIT');
    res.json({ ...upsert.rows[0], allowed_request_types: allowed_request_types || [] });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('POST /mappings error', err);
    res.status(500).json({ error: 'Internal error' });
  } finally {
    client.release();
  }
});

module.exports = router;
