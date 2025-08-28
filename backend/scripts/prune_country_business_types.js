/**
 * Prune country business types to only keep the allowed set for a given country.
 * - By default runs in DRY RUN (no changes). Use --apply to execute deletions.
 * - Targets country_business_types if present; otherwise falls back to legacy business_types (per-country rows).
 *
 * Usage (Windows PowerShell):
 *   node ./backend/scripts/prune_country_business_types.js --country LK            # dry run
 *   node ./backend/scripts/prune_country_business_types.js --country LK --apply   # apply changes
 */
const db = require('../services/database');

function argValue(flag, defVal) {
  const i = process.argv.indexOf(flag);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : defVal;
}

function hasFlag(flag) {
  return process.argv.includes(flag);
}

async function tableExists(table) {
  const q = `SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name=$1`;
  const r = await db.query(q, [table]);
  return r.rows.length > 0;
}

function normalize(s) { return String(s || '').trim().toLowerCase(); }

async function main() {
  const country = argValue('--country', 'LK');
  const apply = hasFlag('--apply');
  const allowed = ['product seller', 'delivery service'];
  console.log(`\n🧹 Pruning business types for country=${country} (apply=${apply})`);

  const hasCountryTable = await tableExists('country_business_types');

  if (hasCountryTable) {
    console.log('➡️ Using table: country_business_types');

    const current = await db.query(
      `SELECT id, name, is_active FROM country_business_types WHERE country_code = $1 ORDER BY display_order, name`,
      [country]
    );

    const toDelete = current.rows.filter(r => !allowed.includes(normalize(r.name)));
    const toKeep = current.rows.filter(r => allowed.includes(normalize(r.name)));

    console.log(`Found ${current.rows.length} rows. Will keep ${toKeep.length}, delete ${toDelete.length}.`);
    if (!toDelete.length) {
      console.log('Nothing to delete. ✅');
      return;
    }

    if (apply) {
      const ids = toDelete.map(r => r.id);
      const del = await db.query(
        `DELETE FROM country_business_types WHERE country_code = $1 AND id = ANY($2::uuid[])`,
        [country, ids]
      );
      console.log(`Deleted ${del.rowCount} rows from country_business_types. ✅`);
    } else {
      console.log('Dry run mode. Rows that would be deleted:');
      toDelete.forEach(r => console.log(` - ${r.id} | ${r.name}`));
    }
  } else {
    console.log('➡️ country_business_types not found. Using legacy: business_types');
    const current = await db.query(
      `SELECT id, name, is_active FROM business_types WHERE country_code = $1 ORDER BY display_order, name`,
      [country]
    );

    const toDelete = current.rows.filter(r => !allowed.includes(normalize(r.name)));
    const toKeep = current.rows.filter(r => allowed.includes(normalize(r.name)));

    console.log(`Found ${current.rows.length} rows. Will keep ${toKeep.length}, delete ${toDelete.length}.`);
    if (!toDelete.length) {
      console.log('Nothing to delete. ✅');
      return;
    }

    if (apply) {
      const ids = toDelete.map(r => r.id);
      const del = await db.query(
        `DELETE FROM business_types WHERE country_code = $1 AND id = ANY($2::uuid[])`,
        [country, ids]
      );
      console.log(`Deleted ${del.rowCount} rows from business_types. ✅`);
    } else {
      console.log('Dry run mode. Rows that would be deleted:');
      toDelete.forEach(r => console.log(` - ${r.id} | ${r.name}`));
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch(err => { console.error('❌ Prune failed:', err); process.exit(1); })
  .finally(async () => { try { await db.close(); } catch (_) {} });
