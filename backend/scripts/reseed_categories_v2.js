/**
 * Reseed categories/subcategories to the new grouped scheme.
 * - Soft-archives existing categories/subcategories by setting is_active=false and tagging metadata.legacy=true
 * - Creates new categories for Products (item, rental) and Services (by module)
 * - Creates subcategories per seed file
 * - Enables categories/subcategories for the configured country (default LK)
 *
 * Usage (Windows PowerShell):
 *   node ./scripts/reseed_categories_v2.js            # uses default seed file ./seed/categories.v2.json
 *   node ./scripts/reseed_categories_v2.js --seed ./path/to/custom.json --country LK --dryRun
 */
const fs = require('fs');
const path = require('path');
const db = require('../services/database');

function log(...args) { console.log('[reseed]', ...args); }

function loadSeed(seedPathCli) {
  const defaultPath = path.join(__dirname, '..', 'seed', 'categories.v2.json');
  const usePath = seedPathCli ? path.resolve(process.cwd(), seedPathCli) : defaultPath;
  if (!fs.existsSync(usePath)) {
    throw new Error(`Seed file not found at ${usePath}`);
  }
  const data = JSON.parse(fs.readFileSync(usePath, 'utf8'));
  return { data, usePath };
}

function slugify(s) {
  return String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

async function backupExisting() {
  const stamp = new Date().toISOString().replace(/[-:TZ.]/g, '').slice(0, 14);
  const backupDir = path.join(__dirname, '..', 'seed', 'backups');
  if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });
  const file = path.join(backupDir, `backup.categories.${stamp}.json`);
  const categories = await db.findMany('categories', {}, { orderBy: 'created_at', orderDirection: 'ASC' });
  const subcats = await db.findMany('sub_categories', {}, { orderBy: 'created_at', orderDirection: 'ASC' });
  fs.writeFileSync(file, JSON.stringify({ categories, sub_categories: subcats }, null, 2));
  return file;
}

async function softArchiveExisting() {
  // Mark all categories/subcategories as inactive and legacy. Keep data for referential integrity.
  await db.query(`UPDATE sub_categories SET is_active = false, metadata = COALESCE(metadata, '{}'::jsonb) || '{"legacy":true}'::jsonb, updated_at = NOW()`);
  await db.query(`UPDATE categories SET is_active = false, metadata = COALESCE(metadata, '{}'::jsonb) || '{"legacy":true}'::jsonb, updated_at = NOW()`);
}

async function upsertCountryCategory(catId, countryCode) {
  const existing = await db.queryOne('SELECT id FROM country_categories WHERE category_id=$1 AND country_code=$2 LIMIT 1', [catId, countryCode]);
  if (existing) {
    await db.query('UPDATE country_categories SET is_active=true, updated_at=NOW() WHERE id=$1', [existing.id]);
  } else {
    await db.query('INSERT INTO country_categories (category_id, country_code, is_active, created_at, updated_at) VALUES ($1,$2,true,NOW(),NOW())', [catId, countryCode]);
  }
}

async function upsertCountrySubcategory(subId, countryCode) {
  const existing = await db.queryOne('SELECT id FROM country_subcategories WHERE subcategory_id=$1 AND country_code=$2 LIMIT 1', [subId, countryCode]);
  if (existing) {
    await db.query('UPDATE country_subcategories SET is_active=true, updated_at=NOW() WHERE id=$1', [existing.id]);
  } else {
    await db.query('INSERT INTO country_subcategories (subcategory_id, country_code, is_active, created_at, updated_at) VALUES ($1,$2,true,NOW(),NOW())', [subId, countryCode]);
  }
}

async function createCategory({ name, description, type, module }) {
  const slug = slugify(module ? `${module}-${name}` : name);
  const metadata = Object.assign({}, description ? { description } : {}, module ? { module } : {});
  // Try reuse existing by slug
  const existing = await db.queryOne('SELECT * FROM categories WHERE slug = $1 LIMIT 1', [slug]);
  if (existing) {
    // Merge metadata and clear legacy flag if present
    let meta = existing.metadata && typeof existing.metadata === 'object' ? { ...existing.metadata } : {};
    if (metadata && typeof metadata === 'object') meta = { ...meta, ...metadata };
    if (meta.legacy) delete meta.legacy;
    const updated = await db.update('categories', existing.id, {
      name,
      type,
      is_active: true,
      metadata: Object.keys(meta).length ? meta : null
    });
    return updated;
  }
  const row = await db.insert('categories', {
    name,
    slug,
    type,
    is_active: true,
    metadata: Object.keys(metadata).length ? metadata : null,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });
  return row;
}

async function createSubcategory(categoryId, { name, description }) {
  const slug = slugify(name);
  const metadata = description ? { description } : null;
  // Try reuse existing by (category_id, slug)
  const existing = await db.queryOne('SELECT * FROM sub_categories WHERE category_id = $1 AND slug = $2 LIMIT 1', [categoryId, slug]);
  if (existing) {
    let meta = existing.metadata && typeof existing.metadata === 'object' ? { ...existing.metadata } : {};
    if (metadata && typeof metadata === 'object') meta = { ...meta, ...metadata };
    if (meta.legacy) delete meta.legacy;
    const updated = await db.update('sub_categories', existing.id, {
      name,
      is_active: true,
      metadata: Object.keys(meta).length ? meta : null
    });
    return updated;
  }
  const row = await db.insert('sub_categories', {
    category_id: categoryId,
    name,
    slug,
    metadata,
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });
  return row;
}

async function reseed({ seed, countryCode = 'LK', dryRun = false }) {
  if (dryRun) log('Running in DRY RUN mode. No writes will be committed.');

  // Validate minimal structure
  if (!seed || typeof seed !== 'object') throw new Error('Invalid seed: expected object');

  // Backup
  const backupPath = await backupExisting();
  log('Backup created at:', backupPath);

  if (dryRun) return { backupPath };

  // Soft-archive old data
  await softArchiveExisting();

  // Insert new data
  let displayOrder = 1;
  const created = [];

  // Items (Products)
  if (seed.item && Array.isArray(seed.item.categories)) {
    for (const cat of seed.item.categories) {
      const catRow = await createCategory({ name: cat.name, description: cat.description, type: 'item' });
      await upsertCountryCategory(catRow.id, countryCode, displayOrder++);
      const subcats = Array.isArray(cat.subcategories) ? cat.subcategories : [];
      for (const sc of subcats) {
        const scRow = await createSubcategory(catRow.id, typeof sc === 'string' ? { name: sc } : sc);
        await upsertCountrySubcategory(scRow.id, countryCode);
      }
      created.push({ type: 'item', id: catRow.id, name: catRow.name });
    }
  }

  // Rentals (Products)
  if (seed.rental && Array.isArray(seed.rental.categories)) {
    for (const cat of seed.rental.categories) {
      const catRow = await createCategory({ name: cat.name, description: cat.description, type: 'rental' });
      await upsertCountryCategory(catRow.id, countryCode, displayOrder++);
      const subcats = Array.isArray(cat.subcategories) ? cat.subcategories : [];
      for (const sc of subcats) {
        const scRow = await createSubcategory(catRow.id, typeof sc === 'string' ? { name: sc } : sc);
        await upsertCountrySubcategory(scRow.id, countryCode);
      }
      created.push({ type: 'rental', id: catRow.id, name: catRow.name });
    }
  }

  // Services by module
  if (seed.service && seed.service.modules && typeof seed.service.modules === 'object') {
    const modules = seed.service.modules;
    for (const [moduleKey, moduleData] of Object.entries(modules)) {
      const categories = moduleData && Array.isArray(moduleData.categories) ? moduleData.categories : [];
      for (const cat of categories) {
        const catRow = await createCategory({ name: cat.name, description: cat.description, type: 'service', module: moduleKey });
        await upsertCountryCategory(catRow.id, countryCode, displayOrder++);
        const subcats = Array.isArray(cat.subcategories) ? cat.subcategories : [];
        for (const sc of subcats) {
          const scRow = await createSubcategory(catRow.id, typeof sc === 'string' ? { name: sc } : sc);
          await upsertCountrySubcategory(scRow.id, countryCode);
        }
        created.push({ type: 'service', module: moduleKey, id: catRow.id, name: catRow.name });
      }
    }
  }

  return { backupPath, createdCount: created.length };
}

async function main() {
  try {
    const args = process.argv.slice(2);
    const seedArgIdx = args.indexOf('--seed');
    const countryIdx = args.indexOf('--country');
    const dryRun = args.includes('--dryRun');
    const seedPathCli = seedArgIdx !== -1 ? args[seedArgIdx + 1] : undefined;
    const countryCode = countryIdx !== -1 ? args[countryIdx + 1] : (process.env.SEED_COUNTRY || undefined);

    const { data: seed, usePath } = loadSeed(seedPathCli);
    const country = countryCode || seed.country || 'LK';

    log('Using seed file:', usePath);
    log('Target country:', country);
    log('Dry run:', dryRun);

    const result = await reseed({ seed, countryCode: country, dryRun });
    log('Done:', result);
    process.exit(0);
  } catch (e) {
    console.error('[reseed] FAILED:', e.message);
    process.exit(1);
  } finally {
    // Ensure pool closes on script end
    try { await db.close(); } catch (_) {}
  }
}

if (require.main === module) {
  main();
}

module.exports = { reseed };
