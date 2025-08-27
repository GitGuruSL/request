#!/usr/bin/env node
// Run a .sql migration file against the DATABASE_URL from production.env or env vars
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');
const dotenv = require('dotenv');

async function main() {
  const cwd = process.cwd();
  const candidates = [
  // Prefer the same file the app uses
    path.join(cwd, '.env.rds'),
    // Fallbacks
    path.join(cwd, 'production.env'),
    path.join(cwd, 'deploy', 'production.env'),
    path.join(cwd, '.env'),
  ];
  let loaded = null;
  for (const p of candidates) {
    if (fs.existsSync(p)) {
      dotenv.config({ path: p });
      loaded = p;
      console.log(`[migrate] Loaded env from ${p}`);
      break;
    }
  }
  if (!loaded) {
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

  let clientConfig;
  if (process.env.DATABASE_URL) {
    clientConfig = { connectionString: process.env.DATABASE_URL };
  } else if (process.env.DB_HOST) {
    clientConfig = {
      host: process.env.DB_HOST,
      port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : undefined,
      database: process.env.DB_NAME,
      user: process.env.DB_USERNAME || process.env.DB_USER,
      password: process.env.DB_PASSWORD || process.env.DB_PASS,
      ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    };
  } else if (process.env.PGHOST) {
    clientConfig = {
      host: process.env.PGHOST,
      port: process.env.PGPORT ? parseInt(process.env.PGPORT, 10) : undefined,
      database: process.env.PGDATABASE,
      user: process.env.PGUSER,
      password: process.env.PGPASSWORD,
      ssl: (process.env.PGSSL === 'true') ? { rejectUnauthorized: false } : false,
    };
  } else {
    console.error('[migrate] DATABASE_URL or DB_* variables missing in environment');
    process.exit(1);
  }

  // Safe log of connection details (no password)
  const safeDetails = clientConfig.connectionString
    ? { connectionString: '***redacted***' }
    : { host: clientConfig.host, port: clientConfig.port, database: clientConfig.database, user: clientConfig.user, ssl: !!clientConfig.ssl };
  console.log('[migrate] Connection details:', safeDetails);

  const client = new Client(clientConfig);
  try {
    await client.connect();
  } catch (e) {
    console.error('[migrate] Could not connect to database:', e.message);
    if (loaded) console.error('[migrate] Env file used:', loaded);
    process.exit(1);
  }
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
