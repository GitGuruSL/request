/**
 * Seed standard business types globally and for a specific country if missing.
 *
 * Types: Product Seller, Delivery, Tours, Events, Construction, Education, Hiring, Other
 *
 * Flags:
 *  --country <CODE>   Country code (default: LK)
 *  --apply            Execute changes (default: dry run)
 *  --globalOnly       Seed only global table
 *  --countryOnly      Seed only country table
 *
 * Examples (PowerShell):
 *  node ./backend/scripts/seed_business_types.js --country LK
 *  node ./backend/scripts/seed_business_types.js --country LK --apply
 */
const db = require('../services/database');

function argValue(flag, defVal) {
  const i = process.argv.indexOf(flag);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : defVal;
}
function hasFlag(flag) { return process.argv.includes(flag); }

const TYPES = [
  { name: 'Product Seller', description: 'Businesses that sell physical products', icon: '🛍️', display_order: 1 },
  { name: 'Delivery', description: 'Courier, logistics, and delivery companies', icon: '🚚', display_order: 5 },
  { name: 'Tours', description: 'Tours and experiences operators and guides', icon: '🧭', display_order: 10 },
  { name: 'Events', description: 'Event planners, venues, rentals, catering', icon: '🎉', display_order: 11 },
  { name: 'Construction', description: 'Contractors, trades, design and materials', icon: '🏗️', display_order: 12 },
  { name: 'Education', description: 'Tutors, institutes, skills and professional courses', icon: '🎓', display_order: 13 },
  { name: 'Hiring', description: 'Recruitment and staffing services', icon: '🧑\u200d💼', display_order: 14 },
  { name: 'Other', description: "Businesses that don't fit other categories", icon: '🏢', display_order: 99 }
];

async function ensureGlobalTypes(apply) {
  const existing = await db.query("SELECT id, name FROM business_types");
  const names = new Set(existing.rows.map(r => (r.name || '').toLowerCase()));
  const missing = TYPES.filter(t => !names.has(t.name.toLowerCase()));
  console.log(`\n[Global] Missing types to insert: ${missing.length}`);
  missing.forEach(t => console.log(` - ${t.name}`));
  if (apply && missing.length) {
    let inserted = 0;
    for (const t of missing) {
      const q = `INSERT INTO business_types (name, description, icon, display_order, is_active, created_at, updated_at)
                 VALUES ($1,$2,$3,$4,true,NOW(),NOW()) RETURNING id`;
      const r = await db.query(q, [t.name, t.description, t.icon, t.display_order || 0]);
      inserted += r.rowCount;
    }
    console.log(`   ✅ Inserted ${inserted} global types`);
  }
}

async function ensureCountryTypes(country, apply) {
  // Check table existence
  const tbl = await db.query(`SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='country_business_types'`);
  if (tbl.rows.length === 0) {
    console.warn('   ⚠️ country_business_types table not found; skipping country seeding');
    return;
  }
  const existing = await db.query("SELECT id, name FROM country_business_types WHERE country_code = $1", [country]);
  const names = new Set(existing.rows.map(r => (r.name || '').toLowerCase()));
  const missing = TYPES.filter(t => !names.has(t.name.toLowerCase()));
  console.log(`\n[Country ${country}] Missing types to insert: ${missing.length}`);
  missing.forEach(t => console.log(` - ${t.name}`));
  if (apply && missing.length) {
    let inserted = 0;
    for (const t of missing) {
      const q = `INSERT INTO country_business_types (name, description, icon, is_active, display_order, country_code, created_at, updated_at)
                 VALUES ($1,$2,$3,true,$4,$5,NOW(),NOW()) RETURNING id`;
      const r = await db.query(q, [t.name, t.description, t.icon, t.display_order || 0, country]);
      inserted += r.rowCount;
    }
    console.log(`   ✅ Inserted ${inserted} country types for ${country}`);
  }
}

async function run() {
  const country = argValue('--country', 'LK');
  const apply = hasFlag('--apply');
  const globalOnly = hasFlag('--globalOnly');
  const countryOnly = hasFlag('--countryOnly');

  console.log(`\n🌱 Seeding business types (apply=${apply}) for country=${country} (globalOnly=${globalOnly}, countryOnly=${countryOnly})`);

  if (!countryOnly) await ensureGlobalTypes(apply);
  if (!globalOnly) await ensureCountryTypes(country, apply);
}

run()
  .then(() => process.exit(0))
  .catch(err => { console.error('❌ Seed failed:', err); process.exit(1); })
  .finally(async () => { try { await db.close(); } catch (_) {} });
