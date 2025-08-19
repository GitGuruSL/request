const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');

// Map incoming UI type to DB page_type
function toDbType(t){
  if(!t) return 'centralized';
  if(t === 'country-specific') return 'country_specific';
  return t; // centralized | template already fine
}

function fromDbType(t){
  if(t === 'country_specific') return 'country-specific';
  return t;
}

// Helper to adapt DB row to API shape expected by frontend
function adapt(row){
  if(!row) return null;
  const metadata = row.metadata || {};
  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    category: metadata.category || 'info',
    type: fromDbType(row.page_type),
    content: row.content,
    countries: row.page_type === 'centralized' ? ['global'] : (row.country_code ? [row.country_code] : []),
  country: row.country_code || null,
    keywords: metadata.keywords || [],
    metaDescription: metadata.metaDescription || metadata.meta_description || null,
    requiresApproval: metadata.requiresApproval ?? true,
    status: row.status,
    isTemplate: row.page_type === 'template' || metadata.isTemplate === true,
    displayOrder: metadata.displayOrder || null,
    metadata,
    targetCountry: row.country_code || null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    createdBy: metadata.createdBy || null,
    updatedBy: metadata.updatedBy || null
  };
}

// List with filters
router.get('/', async (req,res)=>{
  try {
    const { type, country, status, slug, search } = req.query;
    const clauses = [];
    const params = [];
    if(type){ params.push(toDbType(type)); clauses.push(`page_type = $${params.length}`); }
    if(status){ params.push(status); clauses.push(`status = $${params.length}`); }
    if(slug){ params.push(slug); clauses.push(`slug = $${params.length}`); }
    if(country){
      // centralized pages (page_type centralized and country_code IS NULL) OR specific country_code match
      params.push(country);
      clauses.push(`(page_type='centralized' OR country_code = $${params.length})`);
    }
    if(search){
      params.push(`%${search.toLowerCase()}%`);
      clauses.push(`(LOWER(title) LIKE $${params.length} OR LOWER(content) LIKE $${params.length})`);
    }
    let sql = 'SELECT * FROM content_pages';
    if(clauses.length) sql += ' WHERE ' + clauses.join(' AND ');
    sql += ' ORDER BY created_at DESC';
    const result = await db.query(sql, params);
    res.json(result.rows.map(adapt));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Get by id or slug
router.get('/:idOrSlug', async (req,res)=>{
  try {
    const { idOrSlug } = req.params;
    let row;
    if(/^[0-9a-fA-F-]{36}$/.test(idOrSlug)){
      row = await db.findById('content_pages', idOrSlug);
    } else {
      row = await db.queryOne('SELECT * FROM content_pages WHERE slug=$1',[idOrSlug]);
    }
    if(!row) return res.status(404).json({ error:'Not found'});
    res.json(adapt(row));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Create page (country admin or super admin) -> if requiresApproval then status pending else draft/approved
router.post('/', auth.authMiddleware(), async (req,res)=>{
  try {
    const b = req.body || {};
    if(!b.slug || !b.title) return res.status(400).json({ error:'slug and title required' });
    const existing = await db.queryOne('SELECT id FROM content_pages WHERE slug=$1',[b.slug]);
    if(existing) return res.status(409).json({ error:'Slug exists' });
    const user = req.user || {}; 
    const page_type = toDbType(b.type);
    const requiresApproval = b.requiresApproval !== false; // default true for workflow
    let status = b.status || (requiresApproval ? 'pending' : 'draft');
    if(user.role === 'super_admin' && b.status) status = b.status;

    const metadata = {
      category: b.category,
      keywords: b.keywords || [],
      metaDescription: b.metaDescription,
      requiresApproval,
      isTemplate: b.isTemplate === true,
      displayOrder: b.displayOrder,
      createdBy: user.id || null,
      updatedBy: user.id || null
    };

    const row = await db.insert('content_pages', {
      slug: b.slug.toLowerCase(),
      title: b.title,
      page_type,
      country_code: page_type === 'country_specific' ? (b.country || b.country_code || (b.countries && b.countries[0]) || null) : null,
      status,
      metadata,
      content: b.content || ''
    });
    res.status(201).json(adapt(row));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Update page
router.put('/:id', auth.authMiddleware(), async (req,res)=>{
  try {
    const existing = await db.findById('content_pages', req.params.id);
    if(!existing) return res.status(404).json({ error:'Not found'});
    const user = req.user || {};
    const b = req.body || {};
    const update = {};

    if(b.title !== undefined) update.title = b.title;
    if(b.type !== undefined){ update.page_type = toDbType(b.type); }
    if(b.content !== undefined) update.content = b.content;
    if(b.country || b.country_code || b.countries){
      update.country_code = b.country || b.country_code || (Array.isArray(b.countries) ? b.countries[0] : null);
    }
    // Merge metadata
    const metadata = existing.metadata || {};
    if(b.category !== undefined) metadata.category = b.category;
    if(b.keywords !== undefined) metadata.keywords = b.keywords;
    if(b.metaDescription !== undefined) metadata.metaDescription = b.metaDescription;
    if(b.requiresApproval !== undefined) metadata.requiresApproval = b.requiresApproval;
    if(b.isTemplate !== undefined) metadata.isTemplate = b.isTemplate;
    if(b.displayOrder !== undefined) metadata.displayOrder = b.displayOrder;
    metadata.updatedBy = user.id || null;
    update.metadata = metadata;

    if(b.status){
      if(user.role === 'super_admin') update.status = b.status;
      else if(['draft','pending'].includes(existing.status) && b.status === 'pending') update.status = 'pending';
    }

    const row = await db.update('content_pages', req.params.id, update);
    res.json(adapt(row));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Status update endpoint expected by frontend (/content-pages/:id/status)
router.put('/:id/status', auth.authMiddleware(), async (req,res)=>{
  try {
    const existing = await db.findById('content_pages', req.params.id);
    if(!existing) return res.status(404).json({ error:'Not found'});
    const user = req.user || {};
    const { status } = req.body || {};
    if(!status) return res.status(400).json({ error:'status required'});
    // Only super_admin can set approved/published/rejected
    if(['approved','published','rejected'].includes(status) && user.role !== 'super_admin'){
      return res.status(403).json({ error:'Forbidden'});
    }
    // Country admin can move draft->pending
    if(status === 'pending' || user.role === 'super_admin'){
      const row = await db.update('content_pages', req.params.id, { status });
      return res.json(adapt(row));
    }
    return res.status(403).json({ error:'Unauthorized status transition'});
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Approve / Publish (super admin)
router.post('/:id/approve', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req,res)=>{
  try {
    const existing = await db.findById('content_pages', req.params.id);
    if(!existing) return res.status(404).json({ error:'Not found'});
  const row = await db.update('content_pages', req.params.id, { status:'approved' });
    res.json(adapt(row));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

router.post('/:id/publish', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req,res)=>{
  try {
    const existing = await db.findById('content_pages', req.params.id);
    if(!existing) return res.status(404).json({ error:'Not found'});
    const row = await db.update('content_pages', req.params.id, { status:'published' });
    res.json(adapt(row));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Soft delete (mark status=archived) requires super admin
router.delete('/:id', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req,res)=>{
  try {
    const existing = await db.findById('content_pages', req.params.id);
    if(!existing) return res.status(404).json({ error:'Not found'});
    await db.update('content_pages', req.params.id, { status:'archived' });
    res.json({ success:true });
  } catch(e){ res.status(500).json({ error:e.message }); }
});

module.exports = router;
