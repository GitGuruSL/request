const express = require('express');
const db = require('../services/database');
const auth = require('../services/auth');

// Helper: wrap protected handlers but allow dev fallback without auth header
function optionalAuth(handler){
  return async (req,res,next)=>{
    const hasAuthHeader = !!req.headers.authorization;
    const isProd = process.env.NODE_ENV === 'production';

    // Fast path: no header & dev => skip
    if(!hasAuthHeader && !isProd){
      return handler(req,res,next);
    }

    // Try auth, but in dev fall back if it fails
    auth.authMiddleware()(req,res,(err)=>{
      if(err){
        if(!isProd){
          console.warn('[optionalAuth] Auth failed in dev, continuing without user:', err.message);
          return handler(req,res,next);
        }
        return next(err);
      }
      auth.requirePermission('productManagement')(req,res,(permErr)=>{
        if(permErr){
          if(!isProd){
            console.warn('[optionalAuth] Permission check failed in dev, continuing:', permErr.message);
            return handler(req,res,next);
          }
          return next(permErr);
        }
        handler(req,res,next);
      });
    });
  };
}
const router = express.Router();

// Adapter to camelCase expected by frontend
function adapt(row){
  if(!row) return null;
  return {
    id: row.id,
    name: row.name,
    slug: row.slug,
    brandId: row.brand_id || null,
    baseUnit: row.base_unit || null,
    // Normalize possible representations (boolean, int, char)
    isActive: typeof row.is_active === 'boolean'
      ? row.is_active
      : (row.is_active === 1 || row.is_active === '1' || row.is_active === 't' || row.is_active === 'true'),
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}

// GET /api/master-products
router.get('/', async (req, res) => {
  try {
    const { includeInactive = 'false', brandId } = req.query;
    const conditions = {};
    if (brandId) conditions.brand_id = brandId;
    if (includeInactive !== 'true') conditions.is_active = true;
    const rows = await db.findMany('master_products', conditions, { orderBy: 'name', orderDirection: 'ASC' });
    res.json({ success:true, data: rows.map(adapt) });
  } catch(e){ console.error('List master_products error',e); res.status(500).json({success:false,error:e.message}); }
});

router.get('/:id', async (req,res)=>{ try{ const row=await db.findById('master_products', req.params.id); if(!row) return res.status(404).json({success:false,error:'Not found'}); res.json({success:true,data:adapt(row)}); } catch(e){ console.error('Get master product error',e); res.status(500).json({success:false,error:e.message}); }});

router.post('/', optionalAuth(async (req,res)=>{
  try {
    const { name, slug, brandId, baseUnit, isActive = true } = req.body;
    if(!name) return res.status(400).json({ success:false, error:'Name required' });
    const exists = slug ? await db.findMany('master_products', { slug }) : [];
    if (exists.length) return res.status(400).json({ success:false, error:'Slug exists' });
    const row = await db.insert('master_products', { name, slug, brand_id: brandId || null, base_unit: baseUnit || null, is_active: isActive });
    res.status(201).json({ success:true, message:'Product created', data: adapt(row) });
  } catch(e){ console.error('Create master product error',e); res.status(400).json({success:false,error:e.message}); }
}));

router.put('/:id', optionalAuth(async (req,res)=>{
  try {
    const { name, slug, brandId, baseUnit, isActive } = req.body;
    const update = {};
    if (name !== undefined) update.name = name;
    if (slug !== undefined) update.slug = slug;
    if (brandId !== undefined) update.brand_id = brandId;
    if (baseUnit !== undefined) update.base_unit = baseUnit;
    if (isActive !== undefined) update.is_active = isActive;
    if (!Object.keys(update).length) return res.status(400).json({ success:false, error:'No fields to update'});
    const row = await db.update('master_products', req.params.id, update);
    if (!row) return res.status(404).json({ success:false, error:'Not found'});
    res.json({ success:true, message:'Product updated', data: adapt(row) });
  } catch(e){ console.error('Update master product error',e); res.status(400).json({success:false,error:e.message}); }
}));

router.delete('/:id', optionalAuth(async (req,res)=>{
  try { const row = await db.update('master_products', req.params.id, { is_active:false }); if(!row) return res.status(404).json({success:false,error:'Not found'}); res.json({success:true,message:'Product deactivated', data: adapt(row)}); } catch(e){ console.error('Delete master product error',e); res.status(400).json({success:false,error:e.message}); }
}));

// PUT /api/master-products/:id/status (toggle active)
router.put('/:id/status', optionalAuth(async (req,res)=>{
  try {
    const { isActive } = req.body;
    if (typeof isActive !== 'boolean') return res.status(400).json({ success:false, error:'isActive boolean required'});
    const row = await db.update('master_products', req.params.id, { is_active: isActive });
    if(!row) return res.status(404).json({ success:false, error:'Not found'});
    res.json({ success:true, message:'Status updated', data: adapt(row) });
  } catch(e){ console.error('Status update master product error',e); res.status(400).json({success:false,error:e.message}); }
}));

module.exports = router;
