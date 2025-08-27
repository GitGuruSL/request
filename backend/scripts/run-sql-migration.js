#!/usr/bin/env node
// Run a .sql migration file against the DATABASE_URL from production.env or env vars
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');
const dotenv = require('dotenv');

async function main() {
  const cwd = process.cwd();
  const envPath = path.join(cwd, 'production.env');
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
    console.log(`[migrate] Loaded env from ${envPath}`);
  } else {
    dotenv.config();
  }

  const fileArg = process.argv[2];
  if (!fileArg) {
    console.error('Usage: node scripts/run-sql-migration.js <path-to-sql>');
    process.exit(1);
  }
  const sqlPath = path.isAbsolute(fileArg) ? fileArg : path.join(cwd, fileArg);
  if (!fs.existsSync(sqlPath)) {
    console.error(`[migrate] SQL file not found: ${sqlPath}`);
    process.exit(1);
  }
  const sql = fs.readFileSync(sqlPath, 'utf8');

  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error('[migrate] DATABASE_URL missing in environment');
    process.exit(1);
  }

  const client = new Client({ connectionString });
  await client.connect();
  try {
    console.log(`[migrate] Running migration: ${sqlPath}`);
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('[migrate] Migration completed successfully');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[migrate] Migration failed:', err.message);
    process.exitCode = 1;
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('[migrate] Fatal:', e);
  process.exit(1);
});
