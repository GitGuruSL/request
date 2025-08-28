/**
 * Cleanup categories for selected business types in a given country.
 * Sets business_verifications.categories = [] for matching rows
 * so no subcategory subscriptions remain (consistent with no-picker UX).
 *
 * Flags:
 *   --country <CODE>        Country code (default: LK)
 *   --apply                 Execute updates (default: dry run)
 *   --onlyApproved          Limit to approved & verified businesses
 *   --allowed "name1,name2"  Allowed type names (default: "Product Seller,Delivery Service")
 *
 * Usage (Windows PowerShell):
 *   node ./backend/scripts/cleanup_business_categories.js --country LK
 *   node ./backend/scripts/cleanup_business_categories.js --country LK --apply
 *   node ./backend/scripts/cleanup_business_categories.js --country LK --apply --onlyApproved
 */
const db = require('../services/database');

function argValue(flag, defVal) {
  const i = process.argv.indexOf(flag);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : defVal;
}

function hasFlag(flag) {
  return process.argv.includes(flag);
}

function norm(s) { return String(s || '').trim().toLowerCase(); }

async function run() {
  const country = argValue('--country', 'LK');
  const apply = hasFlag('--apply');
  const onlyApproved = hasFlag('--onlyApproved');
  const allowedRaw = argValue('--allowed', 'Product Seller,Delivery Service');
  const allowed = allowedRaw.split(',').map(norm);

  console.log(`\n🧹 Cleaning categories for types [${allowed.join(', ')}] in country=${country} (apply=${apply}, onlyApproved=${onlyApproved})`);

  const baseQuery = `
  SELECT bv.id, bv.user_id, bv.business_name, bv.country, bv.status, bv.is_verified,
       COALESCE(bt.name, '') AS bt_name,
       COALESCE(bv.business_category, '') AS legacy_name,
       bv.categories
    FROM business_verifications bv
    LEFT JOIN business_types bt ON bt.id = bv.business_type_id
    WHERE bv.country = $1
      AND (
    LOWER(COALESCE(bt.name, '')) = ANY($2)
    OR LOWER(COALESCE(bv.business_category, '')) = ANY($2)
      )
    ${onlyApproved ? "AND bv.is_verified = true AND bv.status = 'approved'" : ''}
    ORDER BY bv.created_at DESC
  `;

  const result = await db.query(baseQuery, [country, allowed]);
  const rows = result.rows || [];
  if (!rows.length) {
    console.log('No matching businesses found. ✅');
    return;
  }

  const withNonEmpty = rows.filter(r => Array.isArray(r.categories) ? r.categories.length > 0 : String(r.categories || '[]') !== '[]');
  console.log(`Found ${rows.length} matching businesses; ${withNonEmpty.length} with non-empty categories.`);

  // Show a preview (up to 10)
  withNonEmpty.slice(0, 10).forEach(r => {
    const typeLabel = norm(r.bt_name) || norm(r.legacy_name);
    console.log(` - ${r.id} | ${r.business_name} | type=${typeLabel} | cats=${JSON.stringify(r.categories)}`);
  });
  if (withNonEmpty.length > 10) console.log(` ... and ${withNonEmpty.length - 10} more`);

  if (!apply) {
    console.log('\nDry run complete. Use --apply to execute updates.');
    return;
  }

  // Apply update: set categories = [] for all matches (including null)
  const ids = rows.map(r => r.id);
  const updateQuery = `
    UPDATE business_verifications
    SET categories = '[]'::jsonb, updated_at = NOW()
    WHERE id = ANY($1)
    RETURNING id
  `;
  const upd = await db.query(updateQuery, [ids]);
  console.log(`Updated ${upd.rowCount} business_verifications rows. ✅`);
}

run()
  .then(() => process.exit(0))
  .catch(err => { console.error('❌ Cleanup failed:', err); process.exit(1); })
  .finally(async () => { try { await db.close(); } catch (_) {} });
