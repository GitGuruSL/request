// Minimal entitlement resolver and middleware
// Assumes Express app and Postgres via a db client (pg)

const { Pool } = require('pg');
const pool = new Pool();

function ym(date = new Date()) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  return `${y}${m}`; // 202508
}

async function getEntitlements(userId, role, now = new Date()) {
  const client = await pool.connect();
  try {
    const yearMonth = ym(now);
    // Audience based on role only now
    const audience = role === 'business' ? 'business' : 'normal';

    // Active subscription?
    const subRes = await client.query(`
      SELECT us.*, sp.type AS plan_user_type, sp.plan_type
      FROM user_subscriptions us
      JOIN subscription_plans_new sp ON sp.id = us.plan_id
      WHERE us.user_id = $1 AND us.status IN ('active','trialing','past_due')
      ORDER BY COALESCE(us.next_renewal_at, us.ends_at) DESC NULLS LAST, us.created_at DESC
      LIMIT 1
    `, [userId]);
    const subscription = subRes.rows[0] || null;
    const usageRes = await client.query(
      'SELECT response_count FROM usage_monthly WHERE user_id = $1 AND year_month = $2',
      [userId, yearMonth]
    );
    const responseCount = usageRes.rows[0]?.response_count || 0;
    // Static free limits (can be tuned per audience)
    const freeLimit = audience === 'business' ? -1 : 3; // -1 means unlimited
    const canUnlimited = freeLimit < 0;

    // If subscribed, enable contact + notifications and high limits based on country pricing or plan limitations
    let canViewContact = canUnlimited || responseCount < freeLimit;
    let canMessage = canViewContact;
    if (subscription) {
      canViewContact = true;
      canMessage = true;
    }
    return {
      isSubscribed: !!subscription,
      audience,
      responseCountThisMonth: responseCount,
      canViewContact,
      canMessage,
      subscription
    };
  } finally {
    client.release();
  }
}

function requireResponseEntitlement() {
  return async (req, res, next) => {
    try {
      const userId = req.user?.id; // set by auth middleware
      const role = req.user?.role; // 'normal' | 'business'
      if (!userId) return res.status(401).json({ error: 'unauthorized' });
  const ent = await getEntitlements(userId, role);
  // attach to request for downstream handlers
  req.entitlements = ent;
  if (ent.audience === 'normal' && !ent.isSubscribed && ent.canMessage !== true) {
        return res.status(402).json({ error: 'limit_reached', message: 'Monthly response limit reached' });
      }
      return next();
    } catch (e) {
      console.error('entitlement error', e);
      return res.status(500).json({ error: 'entitlement_failed' });
    }
  };
}

async function incrementResponseCount(userId, now = new Date()) {
  const client = await pool.connect();
  try {
    const yearMonth = ym(now);
    await client.query('BEGIN');
    await client.query(
      `INSERT INTO usage_monthly (user_id, year_month, response_count)
       VALUES ($1, $2, 1)
       ON CONFLICT (user_id, year_month)
       DO UPDATE SET response_count = usage_monthly.response_count + 1, updated_at = now()`,
      [userId, yearMonth]
    );
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

module.exports = { getEntitlements, requireResponseEntitlement, incrementResponseCount };
