const { autoActivateCountryData } = require('../services/adminPermissions');

async function main() {
  const code = (process.argv[2] || 'LK').toUpperCase();
  const name = process.argv[3] || code;
  const adminId = process.argv[4] || null; // may be null; seeding code handles null
  const adminName = process.argv[5] || 'Script Seed';
  try {
    console.log(`Seeding business types for ${name} (${code})...`);
    await autoActivateCountryData(code, name, adminId, adminName);
    console.log('Done.');
    process.exit(0);
  } catch (e) {
    console.error('Seed error:', e);
    process.exit(1);
  }
}

main();
