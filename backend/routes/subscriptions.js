const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');

// Get my active subscription + entitlements summary
router.get('/me', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.id;
    // Latest active subscription
    const sub = await db.queryOne(`
      SELECT us.*, sp.code, sp.name, sp.type AS plan_user_type, sp.plan_type
      FROM user_subscriptions us
      JOIN subscription_plans_new sp ON sp.id = us.plan_id
      WHERE us.user_id = $1 AND us.status IN ('active','trialing','past_due')
      ORDER BY COALESCE(us.next_renewal_at, us.ends_at) DESC NULLS LAST, us.created_at DESC
      LIMIT 1
    `, [userId]);

    res.json({ success: true, data: sub || null });
  } catch (e) {
    console.error('GET /subscriptions/me failed', e);
    res.status(500).json({ success: false, error: 'Failed to load subscription' });
  }
});

// Subscribe to a plan (creates a user_subscriptions row; payment handled client-side via /checkout)
router.post('/', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.id;
    const { plan_id, country_code, promo_code } = req.body || {};
    if (!plan_id || !country_code) return res.status(400).json({ success:false, error:'plan_id and country_code are required' });

    // Plan must be active
    const plan = await db.queryOne('SELECT * FROM subscription_plans_new WHERE id=$1::uuid AND is_active=true', [plan_id]);
    if (!plan) return res.status(400).json({ success:false, error:'Invalid plan' });

    // Determine country price
    const cp = await db.queryOne('SELECT * FROM subscription_country_pricing WHERE plan_id=$1::uuid AND country_code=$2 AND is_active=true', [plan_id, country_code]);
    const price = cp ? Number(cp.price||0) : Number(plan.price||0);
    const currency = cp ? (cp.currency || plan.currency) : plan.currency;

    let promoRow = null;
    if (promo_code) {
      const code = String(promo_code).toUpperCase();
      promoRow = await db.queryOne('SELECT * FROM promo_codes WHERE code = $1 AND is_active = true AND (starts_at IS NULL OR starts_at <= NOW()) AND (expires_at IS NULL OR expires_at >= NOW())', [code]);
    }

    // Apply promo: if metadata.ui_type is like 'freeMonth' or discount makes price 0
    let finalPrice = price;
    let promoMeta = null;
    if (promoRow) {
      const md = promoRow.metadata || {};
      const type = promoRow.discount_type; // 'fixed' or 'percent'
      const val = Number(promoRow.discount_value || 0);
      if (md && (md.ui_type === 'freeMonth' || md.ui_type === 'free')) {
        finalPrice = 0;
      } else if (type === 'fixed') {
        finalPrice = Math.max(0, price - val);
      } else if (type === 'percent') {
        finalPrice = Math.max(0, price * (1 - (val/100)));
      }
      promoMeta = { promo_applied: true, promo_id: promoRow.id, code: promoRow.code, original_price: price, discounted_price: finalPrice };
    }

    const row = await db.queryOne(`
      INSERT INTO user_subscriptions (user_id, plan_id, country_code, status, price, currency, promo_code_id, promo_metadata)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8::jsonb)
      RETURNING *
    `, [userId, plan_id, country_code, finalPrice === 0 ? 'active' : 'pending_payment', finalPrice, currency, promoRow ? promoRow.id : null, JSON.stringify(promoMeta)]);

    res.status(201).json({ success: true, data: row });
  } catch (e) {
    console.error('POST /subscriptions failed', e);
    res.status(500).json({ success:false, error:'Failed to create subscription' });
  }
});

module.exports = router;
