const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');

// Get current user's active/trialing subscription with plan details
router.get('/me', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.id || req.user.userId;
    const sub = await db.queryOne(
      `SELECT s.*, row_to_json(p) AS plan
       FROM subscriptions s
       JOIN subscription_plans_new p ON p.id = s.plan_id
       WHERE s.user_id = $1
         AND s.status IN ('active','trialing')
         AND (s.current_period_end IS NULL OR s.current_period_end > NOW())
       ORDER BY COALESCE(s.current_period_end, s.start_at) DESC NULLS LAST
       LIMIT 1`,
      [userId]
    );
    return res.json({ success: true, data: sub || null });
  } catch (e) {
    console.error('subscriptions/me error', e);
    return res.status(500).json({ success: false, message: 'failed', error: e.message });
  }
});

// Start a subscription (internal provider placeholder)
router.post('/start', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.id || req.user.userId;
    const { plan_id, provider = 'internal', promo_code } = req.body || {};
    if (!plan_id) return res.status(400).json({ success: false, message: 'plan_id required' });
    const plan = await db.findById('subscription_plans_new', plan_id);
    if (!plan || plan.is_active !== true) {
      return res.status(404).json({ success: false, message: 'Plan not found or inactive' });
    }

    // End existing active/trialing subs
    await db.query(
      `UPDATE subscriptions SET status='canceled', cancel_at_period_end=false
       WHERE user_id=$1 AND status IN ('active','trialing')`,
      [userId]
    );

    const durationDays = plan.duration_days || 30;

    // Handle promo code for a free trial period
    if (promo_code && typeof promo_code === 'string' && promo_code.trim()) {
      const code = promo_code.toUpperCase().trim();
      const client = await db.getClient();
      try {
        await client.query('BEGIN');
        const promo = await client.query(
          `SELECT * FROM promo_codes
           WHERE code=$1 AND is_active=true
             AND (starts_at IS NULL OR starts_at <= NOW())
             AND (expires_at IS NULL OR expires_at >= NOW())
           LIMIT 1`,
          [code]
        );
        if (!promo.rowCount) {
          await client.query('ROLLBACK');
          return res.status(400).json({ success:false, message:'Invalid or expired promo code' });
        }
        const promoRow = promo.rows[0];

        // Enforce max uses and per-user limit
        if (promoRow.max_uses != null) {
          const totalUses = await client.query(
            'SELECT COUNT(*)::int AS c FROM promo_code_redemptions WHERE promo_code_id=$1',
            [promoRow.id]
          );
          if (totalUses.rows[0].c >= promoRow.max_uses) {
            await client.query('ROLLBACK');
            return res.status(400).json({ success:false, message:'Promo code usage limit reached' });
          }
        }
        if (promoRow.per_user_limit != null) {
          const userUses = await client.query(
            'SELECT COUNT(*)::int AS c FROM promo_code_redemptions WHERE promo_code_id=$1 AND user_id=$2',
            [promoRow.id, userId]
          );
          if (userUses.rows[0].c >= promoRow.per_user_limit) {
            await client.query('ROLLBACK');
            return res.status(400).json({ success:false, message:'You have already redeemed this promo' });
          }
        }

        // Create a trialing subscription with free period (default durationDays)
        const trialDays = durationDays; // could be overridden by promo.metadata.free_days
        const sub = await client.query(
          `INSERT INTO subscriptions (user_id, plan_id, status, start_at, current_period_end, cancel_at_period_end, provider)
           VALUES ($1,$2,'trialing', NOW(), NOW() + ($3 || ' days')::interval, false, $4)
           RETURNING *`,
          [userId, plan_id, String(trialDays), `promo:${code}`]
        );

        // Record redemption
        await client.query(
          `INSERT INTO promo_code_redemptions (promo_code_id, user_id, request_id, redeemed_at, amount, metadata)
           VALUES ($1,$2,NULL,NOW(),NULL,$3)`,
          [promoRow.id, userId, JSON.stringify({ plan_id, subscription_id: sub.rows[0].id })]
        );

        await client.query('COMMIT');
        return res.status(201).json({ success:true, data: sub.rows[0] });
      } catch (e) {
        try { await client.query('ROLLBACK'); } catch(_){}
        console.error('promo apply error', e);
        return res.status(500).json({ success:false, message:'Failed to apply promo', error:e.message });
      } finally {
        client.release();
      }
    }

    // Normal paid start (no promo)
    const insert = await db.queryOne(
      `INSERT INTO subscriptions (user_id, plan_id, status, start_at, current_period_end, cancel_at_period_end, provider)
       VALUES ($1,$2,'active', NOW(), NOW() + ($3 || ' days')::interval, false, $4)
       RETURNING *`,
      [userId, plan_id, String(durationDays), provider]
    );

    return res.status(201).json({ success: true, data: insert });
  } catch (e) {
    console.error('subscriptions/start error', e);
    return res.status(500).json({ success: false, message: 'failed', error: e.message });
  }
});

// Cancel subscription (at period end by default)
router.post('/cancel', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.id || req.user.userId;
    const { immediate = false } = req.body || {};
    const current = await db.queryOne(
      `SELECT * FROM subscriptions WHERE user_id=$1 AND status IN ('active','trialing')
       ORDER BY current_period_end DESC NULLS LAST LIMIT 1`,
      [userId]
    );
    if (!current) return res.status(404).json({ success: false, message: 'No active subscription' });
    if (immediate) {
      const upd = await db.queryOne(
        `UPDATE subscriptions SET status='canceled', cancel_at_period_end=false WHERE id=$1 RETURNING *`,
        [current.id]
      );
      return res.json({ success: true, data: upd });
    }
    const upd = await db.queryOne(
      `UPDATE subscriptions SET cancel_at_period_end=true WHERE id=$1 RETURNING *`,
      [current.id]
    );
    return res.json({ success: true, data: upd });
  } catch (e) {
    console.error('subscriptions/cancel error', e);
    return res.status(500).json({ success: false, message: 'failed', error: e.message });
  }
});

module.exports = router;
