/**
 * Rename business type from "Delivery Service" to "Delivery".
 *
 * Targets:
 *  - Global table: business_types.name
 *  - Country table: country_business_types.name (optionally per country)
 *  - Optional legacy field: business_verifications.business_category (string)
 *
 * Flags:
 *  --country <CODE>      Limit changes to a country for country_business_types
 *  --allCountries        Apply to all countries (default if --country not provided)
 *  --noGlobal            Skip updating business_types (global)
 *  --migrateLegacy       Also update business_verifications.business_category
 *  --apply               Execute updates (default: dry run)
 *
 * Examples (PowerShell):
 *  node ./backend/scripts/rename_delivery_type.js --country LK
 *  node ./backend/scripts/rename_delivery_type.js --apply --country LK --migrateLegacy
 *  node ./backend/scripts/rename_delivery_type.js --apply --allCountries
 */
const db = require('../services/database');

function argValue(flag, defVal) {
  const i = process.argv.indexOf(flag);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : defVal;
}
function hasFlag(flag) {
  return process.argv.includes(flag);
}

async function run() {
  const country = argValue('--country', null);
  const allCountries = hasFlag('--allCountries') || !country;
  const noGlobal = hasFlag('--noGlobal');
  const migrateLegacy = hasFlag('--migrateLegacy');
  const apply = hasFlag('--apply');

  console.log(`\n🔁 Rename type: "Delivery Service" -> "Delivery" (apply=${apply})`);
  console.log(`   Scope: ${noGlobal ? 'country only' : 'global + country'} | Countries: ${allCountries ? 'ALL' : country}`);
  if (migrateLegacy) console.log('   Also migrating legacy business_verifications.business_category strings');

  // 1) Global business_types
  if (!noGlobal) {
    const preview = await db.query(
      `SELECT id, name FROM business_types WHERE LOWER(name) = 'delivery service'`
    );
    console.log(`\n[Global] Matching business_types rows: ${preview.rowCount}`);
    if (preview.rowCount && !apply) {
      preview.rows.forEach(r => console.log(` - ${r.id} | ${r.name}`));
    }
    if (apply && preview.rowCount) {
      const upd = await db.query(
        `UPDATE business_types SET name = 'Delivery', updated_at = NOW() WHERE LOWER(name) = 'delivery service' RETURNING id, name`
      );
      console.log(`   ✅ Updated ${upd.rowCount} global business_types to 'Delivery'`);
    }
  }

  // 2) Country business types
  let prevCountry;
  if (allCountries) {
    prevCountry = await db.query(
      `SELECT id, name, country_code FROM country_business_types WHERE LOWER(name) = 'delivery service'`
    );
  } else {
    prevCountry = await db.query(
      `SELECT id, name, country_code FROM country_business_types WHERE LOWER(name) = 'delivery service' AND country_code = $1`,
      [country]
    );
  }
  console.log(`\n[Country] Matching country_business_types rows: ${prevCountry.rowCount}`);
  if (prevCountry.rowCount && !apply) {
    prevCountry.rows.slice(0, 20).forEach(r => console.log(` - ${r.id} | ${r.country_code} | ${r.name}`));
    if (prevCountry.rowCount > 20) console.log(` ... and ${prevCountry.rowCount - 20} more`);
  }
  if (apply && prevCountry.rowCount) {
    if (allCountries) {
      const upd = await db.query(
        `UPDATE country_business_types SET name = 'Delivery', updated_at = NOW() WHERE LOWER(name) = 'delivery service'`
      );
      console.log(`   ✅ Updated ${upd.rowCount} country_business_types to 'Delivery'`);
    } else {
      const upd = await db.query(
        `UPDATE country_business_types SET name = 'Delivery', updated_at = NOW() WHERE LOWER(name) = 'delivery service' AND country_code = $1`,
        [country]
      );
      console.log(`   ✅ Updated ${upd.rowCount} country_business_types to 'Delivery'`);
    }
  }

  // 3) Optional legacy field migration
  if (migrateLegacy) {
    const whereLegacy = allCountries ? `LOWER(business_category) = 'delivery service'` : `LOWER(business_category) = 'delivery service' AND country = $1`;
    const legacyPreview = await db.query(
      `SELECT id, business_name, country, business_category FROM business_verifications WHERE ${whereLegacy} ORDER BY created_at DESC LIMIT 50`,
      allCountries ? [] : [country]
    );
    console.log(`\n[Legacy] Matching business_verifications rows: ~${legacyPreview.rowCount} (showing up to 50)`);
    legacyPreview.rows.forEach(r => console.log(` - ${r.id} | ${r.country} | ${r.business_name} | ${r.business_category}`));
    if (apply) {
      const upd = await db.query(
        `UPDATE business_verifications SET business_category = 'Delivery', updated_at = NOW() WHERE ${whereLegacy}`,
        allCountries ? [] : [country]
      );
      console.log(`   ✅ Updated ${upd.rowCount} business_verifications legacy category to 'Delivery'`);
    }
  }
}

run()
  .then(() => process.exit(0))
  .catch(err => { console.error('❌ Rename failed:', err); process.exit(1); })
  .finally(async () => { try { await db.close(); } catch (_) {} });
