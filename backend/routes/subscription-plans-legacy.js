const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');

function adapt(plan){
  if(!plan) return null;
  return {
    id: plan.id,
    planId: plan.code,
    code: plan.code,
    name: plan.name,
    type: plan.type,
    planType: plan.plan_type,
    description: plan.description,
    isActive: plan.is_active,
    isDefaultPlan: plan.is_default_plan,
    requiresCountryPricing: plan.requires_country_pricing,
    countries: plan.countries || [],
    pricingByCountry: plan.pricing_by_country || {},
    features: plan.features || [],
    limitations: plan.limitations || {},
    defaultPrice: Number(plan.price) || 0,
    currency: plan.currency,
    durationDays: plan.duration_days,
    createdAt: plan.created_at,
    updatedAt: plan.updated_at
  };
}

router.get('/subscription-plans', async (req,res)=>{
  try {
    const { country, type } = req.query;
    const conditions = {};
    if(type) conditions.type = type;
    const plans = await db.findMany('subscription_plans_new', conditions, { orderBy:'created_at', orderDirection:'DESC' });
    let adapted = plans.map(adapt);
    if(country){
      adapted = adapted.filter(p => p.countries.includes(country) || p.isDefaultPlan);
    }
    res.json(adapted);
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Seed default plans (legacy path used by admin-react Subscriptions.jsx)
router.post('/subscription-plans/defaults', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req,res)=>{
  const defaults = [
    { code:'rider_free', name:'Rider Free Plan', type:'rider', plan_type:'monthly', description:'Limited free plan for riders with basic features', price:0, currency:'USD', duration_days:30, features:['Browse service requests','Up to 2 responses per month','Basic profile creation','View contact information after selection'], limitations:{ maxResponsesPerMonth:2, riderRequestNotifications:false, unlimitedResponses:false }, is_active:true, is_default_plan:true, requires_country_pricing:false },
    { code:'rider_premium', name:'Rider Premium Plan', type:'rider', plan_type:'monthly', description:'Unlimited plan for active riders', price:10, currency:'USD', duration_days:30, features:['Browse all service requests','Unlimited responses per month','Priority listing in search results','Instant rider request notifications','Advanced profile features','Analytics and insights'], limitations:{ maxResponsesPerMonth:-1, riderRequestNotifications:true, unlimitedResponses:true }, is_active:true, is_default_plan:true, requires_country_pricing:true },
    { code:'business_pay_per_click', name:'Business Pay Per Click', type:'business', plan_type:'pay_per_click', description:'Pay only when someone responds to your requests', price:2, currency:'USD', duration_days:30, features:['Post unlimited service requests','Pay only for responses received','Business profile verification','Priority customer support','Request analytics and reporting'], limitations:{ payPerResponse:true, unlimitedRequests:true }, is_active:true, is_default_plan:true, requires_country_pricing:true }
  ];
  const created=[]; const skipped=[];
  try {
    for(const def of defaults){
      const existing = await db.findMany('subscription_plans_new',{ code:def.code });
      if(existing.length){ skipped.push(def.code); continue; }
      const row = await db.insert('subscription_plans_new', def); created.push(row.code);
    }
    res.json({ success:true, created, skipped });
  } catch(e){ res.status(500).json({ error:e.message, created, skipped }); }
});

router.post('/subscription-plans', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req,res)=>{
  try {
    const b = req.body || {};
  // Derive code from name if not provided
  const derived = (b.name||'').toLowerCase().trim().replace(/[^a-z0-9]+/g,'_').replace(/^_+|_+$/g,'');
  if(!b.planId && !b.code && !derived) return res.status(400).json({ error:'planId/code or valid name required'});
  const code = (b.planId||b.code||derived).toLowerCase();
  const exists = await db.findMany('subscription_plans_new',{ code });
  if(exists.length) return res.status(409).json({ error:'Plan code exists', code });
    const data = {
      code,
      name: b.name,
      type: b.type || 'rider',
      plan_type: b.planType || 'monthly',
      description: b.description || '',
      price: b.defaultPrice ?? 0,
      currency: b.currency || 'USD',
      duration_days: b.durationDays || 30,
      features: b.features || [],
      limitations: b.limitations || {},
      countries: b.countries || [],
      pricing_by_country: b.pricingByCountry || {},
      is_active: b.isActive !== false,
      is_default_plan: b.isDefaultPlan === true,
      requires_country_pricing: b.requiresCountryPricing === true
    };
    const row = await db.insert('subscription_plans_new', data);
    res.status(201).json(adapt(row));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

router.put('/subscription-plans/:id', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req,res)=>{
  try {
    const b = req.body || {};
    const existing = await db.findById('subscription_plans_new', req.params.id);
    if(!existing) return res.status(404).json({ error:'Not found'});
    const update = {};
    if(b.name!==undefined) update.name = b.name;
    if(b.planType!==undefined) update.plan_type = b.planType;
    if(b.type!==undefined) update.type = b.type;
    if(b.description!==undefined) update.description = b.description;
    if(b.features!==undefined) update.features = b.features;
    if(b.limitations!==undefined) update.limitations = b.limitations;
    if(b.countries!==undefined) update.countries = b.countries;
    if(b.pricingByCountry!==undefined) update.pricing_by_country = b.pricingByCountry;
    if(b.defaultPrice!==undefined) update.price = b.defaultPrice;
    if(b.currency!==undefined) update.currency = b.currency;
    if(b.durationDays!==undefined) update.duration_days = b.durationDays;
    if(b.isActive!==undefined) update.is_active = b.isActive;
    if(b.isDefaultPlan!==undefined) update.is_default_plan = b.isDefaultPlan;
    if(b.requiresCountryPricing!==undefined) update.requires_country_pricing = b.requiresCountryPricing;
    const row = await db.update('subscription_plans_new', req.params.id, update);
    res.json(adapt(row));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

router.delete('/subscription-plans/:id', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req,res)=>{
  try { const row = await db.delete('subscription_plans_new', req.params.id); if(!row) return res.status(404).json({ error:'Not found'}); res.json({ success:true }); } catch(e){ res.status(500).json({ error:e.message }); }
});

router.put('/subscription-plans/:id/pricing/:country', auth.authMiddleware(), async (req,res)=>{
  try {
    const plan = await db.findById('subscription_plans_new', req.params.id);
    if(!plan) return res.status(404).json({ error:'Not found'});
    const pricing = plan.pricing_by_country || {}; pricing[req.params.country] = { ...(pricing[req.params.country]||{}), ...req.body };
    const row = await db.update('subscription_plans_new', req.params.id, { pricing_by_country: pricing, countries: Array.from(new Set([...(plan.countries||[]), req.params.country])) });
    res.json(adapt(row));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Approve pricing for a country (sets approvalStatus, isActive)
router.post('/subscription-plans/:id/pricing/:country/approve', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req,res)=>{
  try {
    const plan = await db.findById('subscription_plans_new', req.params.id);
    if(!plan) return res.status(404).json({ error:'Not found'});
    const country = req.params.country;
    const pricing = plan.pricing_by_country || {};
    const prev = pricing[country] || {};
    pricing[country] = { ...prev, approvalStatus:'approved', approvedBy:req.user?.email, approvedAt:new Date(), isActive:true };
    const row = await db.update('subscription_plans_new', req.params.id, { pricing_by_country: pricing, countries: Array.from(new Set([...(plan.countries||[]), country])) });
    res.json(adapt(row));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

// Reject pricing for a country
router.post('/subscription-plans/:id/pricing/:country/reject', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req,res)=>{
  try {
    const plan = await db.findById('subscription_plans_new', req.params.id);
    if(!plan) return res.status(404).json({ error:'Not found'});
    const country = req.params.country;
    const reason = (req.body && req.body.reason) || '';
    const pricing = plan.pricing_by_country || {};
    const prev = pricing[country] || {};
    pricing[country] = { ...prev, approvalStatus:'rejected', rejectedBy:req.user?.email, rejectedAt:new Date(), rejectionReason: reason, isActive:false };
    const row = await db.update('subscription_plans_new', req.params.id, { pricing_by_country: pricing, countries: Array.from(new Set([...(plan.countries||[]), country])) });
    res.json(adapt(row));
  } catch(e){ res.status(500).json({ error:e.message }); }
});

router.get('/user-subscriptions', async (req,res)=>{ res.json([]); });

module.exports = router;
