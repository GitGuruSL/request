const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');

// List plans (optionally by type)
router.get('/', async (req, res) => {
  try {
    const { type, active = 'true' } = req.query;
    const where = [];
    const params = [];
    if (type) { params.push(type); where.push(`type = $${params.length}`); }
    if (active === 'true') where.push('is_active = true');
    const sql = `SELECT * FROM subscription_plans_new ${where.length? 'WHERE ' + where.join(' AND ') : ''} ORDER BY type, price`;
    const r = await db.query(sql, params);
    res.json({ success: true, data: r.rows });
  } catch (e) {
    console.error('List plans failed', e);
    res.status(500).json({ success: false, error: 'Failed to list plans' });
  }
});

// Create plan (super admin only)
router.post('/', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req, res) => {
  try {
    const { code, name, type, plan_type, description, price=0, currency='USD', duration_days=30, features=[], limitations={}, countries=null, is_active=true, is_default_plan=false, requires_country_pricing=false } = req.body || {};
    if (!code || !name || !type || !plan_type) return res.status(400).json({ success:false, error:'code, name, type, plan_type are required' });
    const row = await db.queryOne(`
      INSERT INTO subscription_plans_new (code, name, type, plan_type, description, price, currency, duration_days, features, limitations, countries, is_active, is_default_plan, requires_country_pricing)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9::jsonb,$10::jsonb,$11,$12,$13,$14) RETURNING *
    `, [code, name, type, plan_type, description||null, price, currency, duration_days, JSON.stringify(features||[]), JSON.stringify(limitations||{}), countries, !!is_active, !!is_default_plan, !!requires_country_pricing]);
    res.status(201).json({ success: true, data: row });
  } catch (e) {
    console.error('Create plan failed', e);
    res.status(500).json({ success:false, error:'Failed to create plan' });
  }
});

// Update plan
router.put('/:id', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req,res)=>{
  try {
    const { id } = req.params;
    const prev = await db.queryOne('SELECT * FROM subscription_plans_new WHERE id=$1::uuid', [id]);
    if (!prev) return res.status(404).json({ success:false, error:'Not found' });
    const allowed = ['code','name','type','plan_type','description','price','currency','duration_days','features','limitations','countries','is_active','is_default_plan','requires_country_pricing'];
    const data = {};
    for (const k of allowed) if (k in req.body) data[k] = req.body[k];
    if (data.features) data.features = JSON.stringify(data.features);
    if (data.limitations) data.limitations = JSON.stringify(data.limitations);
    const sets = [];
    const vals = [];
    for (const [k,v] of Object.entries(data)) { vals.push(v); sets.push(`${k} = $${vals.length}`); }
    if (!sets.length) return res.status(400).json({ success:false, error:'No fields to update' });
    vals.push(id);
    const row = await db.queryOne(`UPDATE subscription_plans_new SET ${sets.join(', ')}, updated_at = NOW() WHERE id=$${vals.length}::uuid RETURNING *`, vals);
    res.json({ success:true, data:row });
  } catch (e) {
    console.error('Update plan failed', e);
    res.status(500).json({ success:false, error:'Failed to update plan' });
  }
});

// Country pricing CRUD (country admin)
router.get('/:id/country-pricing', auth.authMiddleware(), auth.roleMiddleware(['super_admin','country_admin']), async (req,res)=>{
  try {
    const { id } = req.params;
    const { country } = req.query;
    const params=[id];
    const where=['plan_id = $1::uuid'];
    if (country){ params.push(country); where.push(`country_code = $${params.length}`); }
    const r = await db.query(`SELECT * FROM subscription_country_pricing WHERE ${where.join(' AND ')} ORDER BY country_code`, params);
    res.json({ success:true, data:r.rows });
  } catch (e) { console.error(e); res.status(500).json({ success:false, error:'Failed to list country pricing' }); }
});

router.post('/:id/country-pricing', auth.authMiddleware(), auth.roleMiddleware(['super_admin','country_admin']), async (req,res)=>{
  try {
    const { id } = req.params;
    const { country_code, price, currency, response_limit, notifications_enabled=true, show_contact_details=true, metadata } = req.body || {};
    if (!country_code) return res.status(400).json({ success:false, error:'country_code is required' });
    const row = await db.queryOne(`
      INSERT INTO subscription_country_pricing (plan_id, country_code, price, currency, response_limit, notifications_enabled, show_contact_details, metadata)
      VALUES ($1::uuid,$2,$3,$4,$5,$6,$7,$8::jsonb)
      ON CONFLICT (plan_id, country_code)
      DO UPDATE SET price=EXCLUDED.price, currency=EXCLUDED.currency, response_limit=EXCLUDED.response_limit,
                    notifications_enabled=EXCLUDED.notifications_enabled, show_contact_details=EXCLUDED.show_contact_details,
                    metadata=EXCLUDED.metadata, updated_at = NOW()
      RETURNING *
    `, [id, country_code, price||0, currency||'USD', response_limit ?? null, !!notifications_enabled, !!show_contact_details, JSON.stringify(metadata||{})]);
    res.status(201).json({ success:true, data:row });
  } catch (e) { console.error(e); res.status(500).json({ success:false, error:'Failed to upsert country pricing' }); }
});

module.exports = router;
