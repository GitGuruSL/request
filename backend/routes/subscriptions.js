const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');

// Get current user's active/trialing subscription with plan details
router.get('/me', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.id || req.user.userId;
    const sub = await db.queryOne(
      `SELECT s.*, p.* AS plan
       FROM subscriptions s
       JOIN subscription_plans_new p ON p.id = s.plan_id
       WHERE s.user_id = $1 AND s.status IN ('active','trialing')
       ORDER BY s.current_period_end DESC NULLS LAST
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
    const { plan_id, provider = 'internal' } = req.body || {};
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
