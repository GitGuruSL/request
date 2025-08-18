#!/usr/bin/env node
/**
 * Hard reset the Postgres schema by dropping all user tables then re-running migrations.
 * SAFETY REQUIREMENTS:
 *   1. Set env var DB_RESET_CONFIRM=YES
 *   2. Not allowed if NODE_ENV === 'production' unless DB_RESET_FORCE=TRUE as well.
 * Usage (PowerShell):
 *   $env:DB_RESET_CONFIRM='YES'; node backend/reset-db.js
 * Optional force (NOT RECOMMENDED): $env:DB_RESET_FORCE='TRUE'
 */

const { Pool } = require('pg');
const path = require('path');
const fs = require('fs');

try { require('dotenv').config({ path: path.join(__dirname, '.env.rds') }); } catch(_){}

if(process.env.DB_RESET_CONFIRM !== 'YES') {
  console.error('Refusing to run. Set DB_RESET_CONFIRM=YES to proceed.');
  process.exit(1);
}
if(process.env.NODE_ENV === 'production' && process.env.DB_RESET_FORCE !== 'TRUE'){
  console.error('Production environment detected. Set DB_RESET_FORCE=TRUE (plus DB_RESET_CONFIRM=YES) to override.');
  process.exit(1);
}

const pool = new Pool({
  host: process.env.DB_HOST || process.env.PGHOST || 'localhost',
  port: Number(process.env.DB_PORT || process.env.PGPORT || 5432),
  user: process.env.DB_USER || process.env.DB_USERNAME || process.env.PGUSER,
  password: process.env.DB_PASSWORD || process.env.PGPASSWORD,
  database: process.env.DB_DATABASE || process.env.DB_NAME || process.env.PGDATABASE,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : (process.env.PGSSL==='true'? { rejectUnauthorized:false }: undefined)
});

async function dropAllTables(){
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    console.log('Enumerating tables...');
    const res = await client.query(`SELECT tablename FROM pg_tables WHERE schemaname='public'`);
    const tables = res.rows.map(r=>r.tablename).filter(t=>t !== 'schema_migrations');
    if(!tables.length){
      console.log('No user tables to drop (except schema_migrations).');
    } else {
      console.log('Dropping tables:', tables.join(', '));
      for(const t of tables){
        console.log(`DROP TABLE ${t} CASCADE`);
        await client.query(`DROP TABLE IF EXISTS ${t} CASCADE`);
      }
    }
    console.log('Dropping schema_migrations to allow clean re-run');
    await client.query('DROP TABLE IF EXISTS schema_migrations');
    await client.query('COMMIT');
    console.log('✅ All tables dropped.');
  } catch (e){
    await client.query('ROLLBACK');
    console.error('❌ Failed during drop:', e.message);
    process.exit(1);
  } finally {
    client.release();
  }
}

async function runMigrations(){
  console.log('\nRe-applying migrations...');
  const runnerPath = path.join(__dirname, 'run-all-migrations.js');
  if(!fs.existsSync(runnerPath)) { console.error('Migration runner not found at', runnerPath); process.exit(1);} 
  const { spawn } = require('child_process');
  await new Promise((resolve, reject)=>{
    const proc = spawn(process.execPath, [runnerPath], { stdio: 'inherit' });
    proc.on('exit', code => { if(code===0) resolve(); else reject(new Error('Migration runner exited with code '+code)); });
  });
}

(async ()=>{
  console.log('⚠️  DESTROYING DATABASE SCHEMA for', process.env.DB_DATABASE);
  await dropAllTables();
  await runMigrations();
  console.log('\n🎉 Reset complete.');
  await pool.end();
})();
