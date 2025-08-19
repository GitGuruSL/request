const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');

function buildUpdate(fields) {
  const sets = [];
  const values = [];
  let i = 1;
  for (const [k,v] of Object.entries(fields)) {
    if (v !== undefined) { sets.push(`${k} = $${i++}`); values.push(v); }
  }
  if (!sets.length) return null;
  sets.push(`updated_at = NOW()`);
  return { clause: sets.join(', '), values };
}

// GET /api/countries
router.get('/', async (req,res) => {
  try {
    const { search, active, limit = 100, offset = 0 } = req.query;
    const where = [];
    const params = [];
    let p = 1;
    if (active === '1' || active === 'true') { where.push(`is_active = true`); }
    if (active === '0' || active === 'false') { where.push(`is_active = false`); }
    if (search) {
      where.push(`(code ILIKE $${p} OR name ILIKE $${p})`);
      params.push(`%${search}%`); p++;
    }
    const whereSql = where.length ? 'WHERE ' + where.join(' AND ') : '';
    const totalResult = await db.query(`SELECT COUNT(*)::int AS count FROM countries ${whereSql}`, params);
    const total = totalResult.rows[0].count;
    const l = Math.min(parseInt(limit)||100, 500);
    const o = parseInt(offset)||0;
    const dataResult = await db.query(`SELECT * FROM countries ${whereSql} ORDER BY name LIMIT ${l} OFFSET ${o}`, params);
    res.json({ success:true, data: dataResult.rows, total, limit:l, offset:o });
  } catch (e) {
    console.error('List countries error', e);
    res.status(500).json({ success:false, message:'Error listing countries' });
  }
});

// Public list for mobile selection (must be BEFORE :codeOrId)
router.get('/public', async (req,res)=>{
  try {
    const rows = await db.query('SELECT code,name,default_currency,phone_prefix,locale,tax_rate,flag_url,is_active FROM countries ORDER BY name');
    const data = rows.rows.map(r=>({
      code: r.code,
      name: r.name,
      phoneCode: r.phone_prefix,
      currency: r.default_currency,
      flagUrl: r.flag_url,
      isActive: r.is_active,
      comingSoon: !r.is_active,
      statusLabel: r.is_active ? 'Active' : 'Coming Soon',
      comingSoonMessage: !r.is_active ? 'This country is coming soon. Please select an active country.' : null
    }));
    res.json({ success:true, data });
  } catch(e){
    console.error('Public countries list error', e);
    res.status(500).json({ success:false, message:'Error loading countries'});
  }
});

// GET /api/countries/:codeOrId
router.get('/:codeOrId', async (req,res) => {
  try {
    const v = req.params.codeOrId;
    let row;
    if (/^\d+$/.test(v)) {
      row = await db.queryOne('SELECT * FROM countries WHERE id = $1', [parseInt(v,10)]);
    } else {
      row = await db.queryOne('SELECT * FROM countries WHERE code = $1', [v.toUpperCase()]);
    }
    if (!row) return res.status(404).json({ success:false, message:'Country not found' });
    res.json({ success:true, data: row });
  } catch (e) {
    console.error('Get country error', e);
    res.status(500).json({ success:false, message:'Error fetching country' });
  }
});

// POST /api/countries
router.post('/', auth.authMiddleware(), auth.roleMiddleware(['admin','super_admin']), async (req,res) => {
  try {
    const { code, name, default_currency, phone_prefix, locale, tax_rate, flag_url, is_active = true } = req.body;
    if (!code || !name) return res.status(400).json({ success:false, message:'code and name required' });
    const existing = await db.queryOne('SELECT id FROM countries WHERE code = $1', [code.toUpperCase()]);
    if (existing) return res.status(409).json({ success:false, message:'Country code already exists' });
    const row = await db.queryOne(`INSERT INTO countries (code, name, default_currency, phone_prefix, locale, tax_rate, flag_url, is_active)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING *`, [code.toUpperCase(), name, default_currency || 'USD', phone_prefix, locale, tax_rate, flag_url, is_active]);
    res.status(201).json({ success:true, message:'Country created', data: row });
  } catch (e) {
    console.error('Create country error', e);
    res.status(500).json({ success:false, message:'Error creating country' });
  }
});

// PUT /api/countries/:codeOrId
router.put('/:codeOrId', auth.authMiddleware(), auth.roleMiddleware(['admin','super_admin']), async (req,res) => {
  try {
    const v = req.params.codeOrId;
    const fields = { name: req.body.name, default_currency: req.body.default_currency, phone_prefix: req.body.phone_prefix, locale: req.body.locale, tax_rate: req.body.tax_rate, flag_url: req.body.flag_url, is_active: req.body.is_active };
    const upd = buildUpdate(fields);
    if (!upd) return res.status(400).json({ success:false, message:'No valid fields to update' });
    let row;
    if (/^\d+$/.test(v)) {
      upd.values.push(parseInt(v,10));
      row = await db.queryOne(`UPDATE countries SET ${upd.clause} WHERE id = $${upd.values.length} RETURNING *`, upd.values);
    } else {
      upd.values.push(v.toUpperCase());
      row = await db.queryOne(`UPDATE countries SET ${upd.clause} WHERE code = $${upd.values.length} RETURNING *`, upd.values);
    }
    if (!row) return res.status(404).json({ success:false, message:'Country not found' });
    res.json({ success:true, message:'Country updated', data: row });
  } catch (e) {
    console.error('Update country error', e);
    res.status(500).json({ success:false, message:'Error updating country' });
  }
});

// DELETE (soft deactivate)
router.delete('/:codeOrId', auth.authMiddleware(), auth.roleMiddleware(['admin','super_admin']), async (req,res) => {
  try {
    const v = req.params.codeOrId;
    let row;
    if (/^\d+$/.test(v)) {
      row = await db.queryOne('UPDATE countries SET is_active = false, updated_at = NOW() WHERE id = $1 RETURNING *', [parseInt(v,10)]);
    } else {
      row = await db.queryOne('UPDATE countries SET is_active = false, updated_at = NOW() WHERE code = $1 RETURNING *', [v.toUpperCase()]);
    }
    if (!row) return res.status(404).json({ success:false, message:'Country not found' });
    res.json({ success:true, message:'Country deactivated', data: row });
  } catch (e) {
    console.error('Deactivate country error', e);
    res.status(500).json({ success:false, message:'Error deactivating country' });
  }
});

module.exports = router;

// Additional endpoint for status toggle expected by frontend: PUT /api/countries/:codeOrId/status
router.put('/:codeOrId/status', auth.authMiddleware(), auth.roleMiddleware(['admin','super_admin']), async (req,res) => {
  try {
    const v = req.params.codeOrId;
    const desired = req.body && typeof req.body.isActive === 'boolean' ? req.body.isActive : undefined;
    let row;
    if (/^\d+$/.test(v)) {
      row = await db.queryOne('SELECT * FROM countries WHERE id=$1',[parseInt(v,10)]);
    } else {
      row = await db.queryOne('SELECT * FROM countries WHERE code=$1',[v.toUpperCase()]);
    }
    if(!row) return res.status(404).json({ success:false, message:'Country not found'});
    const newVal = desired !== undefined ? desired : !row.is_active;
    let updated;
    if (/^\d+$/.test(v)) {
      updated = await db.queryOne('UPDATE countries SET is_active=$1, updated_at=NOW() WHERE id=$2 RETURNING *',[newVal, parseInt(v,10)]);
    } else {
      updated = await db.queryOne('UPDATE countries SET is_active=$1, updated_at=NOW() WHERE code=$2 RETURNING *',[newVal, v.toUpperCase()]);
    }
    res.json({ success:true, message:'Status updated', data: updated });
  } catch(e){
    console.error('Toggle country status error', e);
    res.status(500).json({ success:false, message:'Error updating country status'});
  }
});
