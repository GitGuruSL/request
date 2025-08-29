const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');

// List effective plans for a country (merge base + overrides)
router.get('/', async (req, res) => {
  try {
    const { country } = req.query;
    const base = await db.query('SELECT * FROM subscription_plans_new WHERE is_active = true ORDER BY created_at DESC');
    if (!country) return res.json(base.rows);
    const cc = String(country).toUpperCase();
    const overrides = await db.query('SELECT * FROM subscription_plan_country_pricing WHERE country_code = $1', [cc]);
    const map = new Map(overrides.rows.map(o => [o.plan_id, o]));
    const merged = base.rows.map(p => {
      const o = map.get(p.id);
      if (!o) return p;
      return {
        ...p,
        price: o.price ?? p.price,
        currency: o.currency ?? p.currency,
        limitations: { ...(p.limitations||{}), ...(o.limitations||{}) },
        is_active: (o.is_active == null ? p.is_active : o.is_active)
      };
    });
    res.json(merged);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Upsert override (country_admin limited to own country)
router.put('/:planId/:country', auth.authMiddleware(), auth.roleMiddleware(['super_admin','country_admin']), async (req, res) => {
  try {
    const { planId, country } = req.params;
    const body = req.body || {};
    const cc = String(country).toUpperCase();
    if (req.user.role === 'country_admin') {
      const ucc = (req.user.country_code||'').toUpperCase();
      if (!ucc || ucc !== cc) return res.status(403).json({ error: 'Wrong country' });
    }
    // ensure plan exists
    const plan = await db.findById('subscription_plans_new', planId);
    if (!plan) return res.status(404).json({ error: 'Plan not found' });
    const row = await db.queryOne(`
      INSERT INTO subscription_plan_country_pricing (plan_id, country_code, price, currency, limitations, is_active)
      VALUES ($1,$2,$3,$4,$5::jsonb,$6)
      ON CONFLICT (plan_id, country_code)
      DO UPDATE SET price = EXCLUDED.price, currency = EXCLUDED.currency, limitations = EXCLUDED.limitations, is_active = EXCLUDED.is_active, updated_at = NOW()
      RETURNING *
    `, [planId, cc, body.price ?? null, body.currency ?? null, JSON.stringify(body.limitations||{}), body.is_active ?? null]);
    res.json({ success:true, data: row });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Delete override
router.delete('/:planId/:country', auth.authMiddleware(), auth.roleMiddleware(['super_admin','country_admin']), async (req, res) => {
  try {
    const { planId, country } = req.params;
    const cc = String(country).toUpperCase();
    if (req.user.role === 'country_admin') {
      const ucc = (req.user.country_code||'').toUpperCase();
      if (!ucc || ucc !== cc) return res.status(403).json({ error: 'Wrong country' });
    }
    const del = await db.queryOne('DELETE FROM subscription_plan_country_pricing WHERE plan_id=$1 AND country_code=$2 RETURNING *', [planId, cc]);
    if (!del) return res.status(404).json({ error: 'Not found' });
    res.json({ success:true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
