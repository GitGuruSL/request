// Simple Firebase to PostgreSQL data importer
// Usage: node import_firebase_data.js
// This directly inserts your Firebase data into the replica tables

require('dotenv').config({ path: '.env.rds' });
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
});

// Your Firebase data (paste your actual data here)
const firebaseData = {
  admin_users: [
    {
      firebase_id: 'admin1',
      email: 'superadmin@request.lk',
      name: 'Super Administrator',
      role: 'super_admin',
      is_active: true,
      permissions: {
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
      },
      created_at: new Date('2025-08-13T16:42:13.000Z'),
      last_permission_update: new Date('2025-08-16T09:52:07.000Z')
    }
  ],
  
  app_countries: [
    {
      firebase_id: 'TH',
      code: 'TH',
      name: 'Thailand',
      flag: '🇹🇭',
      phone_code: '+66',
      is_enabled: false,
      coming_soon_message: 'Coming soon to your country! Stay tuned for updates.',
      created_at: new Date('2025-08-13T19:23:18.000Z'),
      updated_at: new Date('2025-08-13T19:41:21.000Z')
    }
  ],

  cities: [
    {
      firebase_id: 'city_matara',
      name: 'Matara',
      country_code: 'LK',
      description: 'Matara city in Sri Lanka',
      population: 58209,
      coordinates: { lat: null, lng: null },
      is_active: true,
      created_by: 'country_admin',
      updated_by: 'country_admin',
      created_at: new Date('2025-08-14T15:21:53.000Z'),
      updated_at: new Date('2025-08-14T15:21:53.000Z')
    }
  ]
};

async function importData() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Import admin_users
    console.log('Importing admin_users...');
    for (const user of firebaseData.admin_users) {
      await client.query(`
        INSERT INTO admin_users (firebase_id, email, name, role, is_active, permissions, created_at, last_permission_update)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        ON CONFLICT (firebase_id) DO UPDATE SET
          email = EXCLUDED.email,
          name = EXCLUDED.name,
          role = EXCLUDED.role,
          is_active = EXCLUDED.is_active,
          permissions = EXCLUDED.permissions,
          updated_at = NOW()
      `, [
        user.firebase_id,
        user.email,
        user.name,
        user.role,
        user.is_active,
        JSON.stringify(user.permissions),
        user.created_at,
        user.last_permission_update
      ]);
    }
    
    // Import app_countries
    console.log('Importing app_countries...');
    for (const country of firebaseData.app_countries) {
      await client.query(`
        INSERT INTO app_countries (firebase_id, code, name, flag, phone_code, is_enabled, coming_soon_message, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (firebase_id) DO UPDATE SET
          name = EXCLUDED.name,
          flag = EXCLUDED.flag,
          phone_code = EXCLUDED.phone_code,
          is_enabled = EXCLUDED.is_enabled,
          coming_soon_message = EXCLUDED.coming_soon_message,
          updated_at = NOW()
      `, [
        country.firebase_id,
        country.code,
        country.name,
        country.flag,
        country.phone_code,
        country.is_enabled,
        country.coming_soon_message,
        country.created_at,
        country.updated_at
      ]);
    }
    
    // Import cities
    console.log('Importing cities...');
    for (const city of firebaseData.cities) {
      await client.query(`
        INSERT INTO cities (firebase_id, name, country_code, description, population, coordinates, is_active, created_by, updated_by, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        ON CONFLICT (firebase_id) DO UPDATE SET
          name = EXCLUDED.name,
          country_code = EXCLUDED.country_code,
          description = EXCLUDED.description,
          population = EXCLUDED.population,
          coordinates = EXCLUDED.coordinates,
          is_active = EXCLUDED.is_active,
          updated_by = EXCLUDED.updated_by,
          updated_at = NOW()
      `, [
        city.firebase_id,
        city.name,
        city.country_code,
        city.description,
        city.population,
        JSON.stringify(city.coordinates),
        city.is_active,
        city.created_by,
        city.updated_by,
        city.created_at,
        city.updated_at
      ]);
    }
    
    await client.query('COMMIT');
    console.log('✅ All data imported successfully!');
    
    // Show results
    const adminCount = await client.query('SELECT COUNT(*) FROM admin_users');
    const countryCount = await client.query('SELECT COUNT(*) FROM app_countries');
    const cityCount = await client.query('SELECT COUNT(*) FROM cities');
    
    console.log(`📊 Results:`);
    console.log(`   admin_users: ${adminCount.rows[0].count}`);
    console.log(`   app_countries: ${countryCount.rows[0].count}`);
    console.log(`   cities: ${cityCount.rows[0].count}`);
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Import failed:', error);
  } finally {
    client.release();
    await pool.end();
  }
}

// Run the import
importData().catch(console.error);
