/**
 * Backfill categories.request_type from categories.type
 * - Normalizes legacy 'rent' -> 'rental'
 * - By default only fills NULL/empty request_type
 * - Use --forceAll to overwrite all rows
 */
const db = require('../services/database');

async function run({ forceAll = false } = {}) {
  const where = forceAll ? 'TRUE' : "(request_type IS NULL OR request_type = '' )";
  const sql = `
    UPDATE categories
    SET request_type = CASE WHEN type = 'rent' THEN 'rental' ELSE type END,
        updated_at = NOW()
    WHERE ${where}
    RETURNING id, name, type, request_type
  `;
  const res = await db.query(sql);
  return { updated: res.rowCount };
}

async function main() {
  const forceAll = process.argv.includes('--forceAll');
  try {
    const result = await run({ forceAll });
    console.log('[backfill] Updated rows:', result.updated);
    process.exit(0);
  } catch (e) {
    console.error('[backfill] FAILED:', e.message);
    process.exit(1);
  } finally {
    try { await db.close(); } catch (_) {}
  }
}

if (require.main === module) main();

module.exports = { run };
