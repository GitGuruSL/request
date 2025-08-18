// Simple script to ensure a fresh super admin exists without needing Firebase UID
// Usage (PowerShell): node seed_super_admin.js -e superadmin@request.lk -p YourPassword123!

require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const args = process.argv.slice(2);
function getArg(flag, def=null){ const i=args.indexOf(flag); return i>=0? args[i+1]: def; }
const email = (getArg('-e') || process.env.ADMIN_EMAIL || 'superadmin@request.lk').toLowerCase();
const password = getArg('-p') || process.env.ADMIN_PASSWORD || 'ChangeMe123!';
const displayName = getArg('-n') || process.env.ADMIN_NAME || 'Super Administrator';

(async ()=>{
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    host: process.env.PGHOST,
    port: process.env.PGPORT,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    database: process.env.PGDATABASE,
    ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized:false } : undefined
  });
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query('SELECT id, email, role FROM users WHERE email=$1', [email]);
    if (rows.length) {
      console.log(`[seed_super_admin] User already exists: ${email} (role=${rows[0].role})`);
    } else {
      const hash = await bcrypt.hash(password, 12);
      // Ensure permissions column exists (migration 004)
      await client.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS permissions JSONB');
      const fullPermissions = {
        adminUsersManagement: true,
        brandManagement: true,
        businessManagement: true,
        categoryManagement: true,
        cityManagement: true,
        contentManagement: true,
        countryBrandManagement: true,
        countryCategoryManagement: true,
        countryPageManagement: true,
        countryProductManagement: true,
        countrySubcategoryManagement: true,
        countryVariableTypeManagement: true,
        countryVehicleTypeManagement: true,
        driverManagement: true,
        driverVerification: true,
        legalDocumentManagement: true,
        legalDocuments: true,
        moduleManagement: true,
        paymentMethodManagement: true,
        paymentMethods: true,
        priceListingManagement: true,
        productManagement: true,
        promoCodeManagement: true,
        requestManagement: true,
        responseManagement: true,
        subcategoryManagement: true,
        subscriptionManagement: true,
        userManagement: true,
        variableTypeManagement: true,
        vehicleManagement: true
      };
      const inserted = await client.query(`INSERT INTO users (email, password_hash, display_name, role, is_active, email_verified, phone_verified, country_code, permissions)
        VALUES ($1,$2,$3,'super_admin',TRUE,TRUE,TRUE,'LK',$4) RETURNING id, email, role`, [email, hash, displayName, fullPermissions]);
      console.log(`[seed_super_admin] Created super admin ${inserted.rows[0].email}`);
      console.log('[seed_super_admin] IMPORTANT: Change the password after first login.');
    }
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('[seed_super_admin] Error:', e.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
})();
