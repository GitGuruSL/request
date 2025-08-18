const express = require('express');
const router = express.Router();
const db = require('../services/database');

// Basic list
router.get('/', async (req,res)=>{
  try {
    const { type, active } = req.query;
    const conditions = {};
    if(type) conditions.type = type;
    if(active !== undefined) conditions.is_active = active === 'true';
    const rows = await db.findMany('subscription_plans_new', conditions, { orderBy: 'created_at', orderDirection: 'DESC' });
    res.json(rows);
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Get one
router.get('/:id', async (req,res)=>{
  try { const row = await db.findById('subscription_plans_new', req.params.id); if(!row) return res.status(404).json({error:'Not found'}); res.json(row);} catch(e){ res.status(500).json({ error:e.message }); }
});

// Create
router.post('/', async (req,res)=>{
  try {
    const data = req.body || {};
    if(!data.code || !data.name) return res.status(400).json({error:'code and name required'});
    data.features = data.features || [];
    data.limitations = data.limitations || {};
    const existing = await db.findMany('subscription_plans_new', { code: data.code });
    if(existing.length) return res.status(409).json({ error:'Code already exists'});
    const row = await db.insert('subscription_plans_new', data);
    res.status(201).json(row);
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Update
router.put('/:id', async (req,res)=>{
  try {
    const data = req.body || {};
    if(data.code){ // ensure uniqueness
      const dup = await db.query('SELECT 1 FROM subscription_plans_new WHERE code=$1 AND id<>$2 LIMIT 1',[data.code, req.params.id]);
      if(dup.rowCount) return res.status(409).json({ error:'Code already exists'});
    }
    const row = await db.update('subscription_plans_new', req.params.id, data);
    if(!row) return res.status(404).json({error:'Not found'});
    res.json(row);
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Delete
router.delete('/:id', async (req,res)=>{
  try { const row = await db.delete('subscription_plans_new', req.params.id); if(!row) return res.status(404).json({error:'Not found'}); res.json({ success:true }); } catch(e){ res.status(500).json({ error:e.message }); }
});

module.exports = router;
