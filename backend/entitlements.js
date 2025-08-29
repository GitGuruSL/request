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

    const subRes = await client.query(
      `SELECT s.status, s.current_period_end, p.audience, p.model
       FROM subscriptions s
       JOIN subscription_plans p ON p.id = s.plan_id
       WHERE s.user_id = $1 AND s.status IN ('active','trialing')
       ORDER BY s.current_period_end DESC NULLS LAST
       LIMIT 1`,
      [userId]
    );

    const sub = subRes.rows[0] || null;
    const isSubscribed = !!sub;
    const audience = sub?.audience || (role === 'business' ? 'business' : 'normal');

    const usageRes = await client.query(
      'SELECT response_count FROM usage_monthly WHERE user_id = $1 AND year_month = $2',
      [userId, yearMonth]
    );
    const responseCount = usageRes.rows[0]?.response_count || 0;

    let canViewContact = false;
    let canMessage = false;

    if (isSubscribed) {
      canViewContact = true;
      canMessage = true;
    } else if (audience === 'normal') {
      canViewContact = responseCount < 3;
      canMessage = responseCount < 3;
    } else if (audience === 'business') {
      // For business without active monthly sub, allow view (PPC logic elsewhere)
      canViewContact = true;
      canMessage = true;
    }

    return {
      isSubscribed,
      audience,
      responseCountThisMonth: responseCount,
      canViewContact,
      canMessage,
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
      if (ent.audience === 'normal' && !ent.isSubscribed && ent.responseCountThisMonth >= 3) {
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
