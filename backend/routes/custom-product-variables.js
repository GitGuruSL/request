const express = require('express');
const db = require('../services/database');
const auth = require('../services/auth');
const router = express.Router();

function normalize(row){
  let parsed = null; if(row.value){ try { parsed = JSON.parse(row.value);} catch(_){} }
  return {
    id: row.id,
    firebaseId: row.firebase_id,
    key: row.key,
    name: parsed?.name || row.key,
    description: row.description || parsed?.description || null,
    type: row.type || 'text',
    possibleValues: Array.isArray(parsed?.options)?parsed.options:[],
    isRequired: parsed?.isRequired || false,
    isActive: row.is_active !== false,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}

async function listVariables(req,res){
  try {
    const { includeInactive='false' } = req.query;
    const where = includeInactive==='true' ? '' : 'WHERE is_active = true';
    const rows = await db.query(`SELECT * FROM custom_product_variables ${where} ORDER BY key ASC`);
    res.json({ success:true, data: rows.rows.map(normalize), count: rows.rows.length });
  } catch(e){
    console.error('List custom product variables error', e);
    res.status(500).json({ success:false, error: e.message });
  }
}
router.get('/custom_product_variables', auth.authMiddleware(), listVariables);
router.get('/custom-product-variables', auth.authMiddleware(), listVariables);

router.get('/custom-product-variables/:id', auth.authMiddleware(), async (req,res)=>{ try{ const row=await db.findById('custom_product_variables', req.params.id); if(!row) return res.status(404).json({success:false,error:'Not found'}); res.json({success:true,data:normalize(row)});} catch(e){ console.error('Get variable error',e); res.status(500).json({success:false,error:e.message}); }});

router.post('/custom-product-variables', auth.authMiddleware(), async (req,res)=>{
  try { if(req.user.role !== 'super_admin') return res.status(403).json({success:false,error:'Only super admins can create variables'}); const { key, name, description, type='text', possibleValues=[], isRequired=false, isActive=true } = req.body; if(!key && !name) return res.status(400).json({success:false,error:'key or name required'}); const k = key || name.toLowerCase().replace(/[^a-z0-9]+/g,'_'); const value = JSON.stringify({ name: name || k, options: possibleValues, isRequired }); const row = await db.insert('custom_product_variables', { key:k, value, type, description, is_active:isActive }); res.status(201).json({ success:true, message:'Variable created', data: normalize(row) }); } catch(e){ console.error('Create variable error',e); res.status(400).json({ success:false, error:e.message }); }
});

router.put('/custom-product-variables/:id', auth.authMiddleware(), async (req,res)=>{
  try { if(req.user.role !== 'super_admin') return res.status(403).json({success:false,error:'Only super admins can update variables'}); const { name, description, type, possibleValues, isRequired, isActive } = req.body; const existing = await db.findById('custom_product_variables', req.params.id); if(!existing) return res.status(404).json({success:false,error:'Not found'}); const parsed = existing.value ? (()=>{try{return JSON.parse(existing.value);}catch{return {};}})():{}; if(name!==undefined) parsed.name = name; if(possibleValues!==undefined) parsed.options = possibleValues; if(isRequired!==undefined) parsed.isRequired = isRequired; const update = {}; if(description!==undefined) update.description = description; if(type!==undefined) update.type = type; if(isActive!==undefined) update.is_active = isActive; update.value = JSON.stringify(parsed); const row = await db.update('custom_product_variables', req.params.id, update); res.json({ success:true, message:'Variable updated', data: normalize(row) }); } catch(e){ console.error('Update variable error',e); res.status(400).json({ success:false, error:e.message }); }
});

router.delete('/custom-product-variables/:id', auth.authMiddleware(), async (req,res)=>{ try { if(req.user.role !== 'super_admin') return res.status(403).json({success:false,error:'Only super admins can delete variables'}); const row = await db.update('custom_product_variables', req.params.id, { is_active:false }); if(!row) return res.status(404).json({success:false,error:'Not found'}); res.json({ success:true, message:'Variable deactivated'}); } catch(e){ console.error('Delete variable error',e); res.status(400).json({ success:false, error:e.message }); }});

module.exports = router;
