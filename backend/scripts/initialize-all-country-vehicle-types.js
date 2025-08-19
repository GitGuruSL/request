#!/usr/bin/env node

/**
 * Bulk initialization script for country vehicle types
 * This script will initialize vehicle types for ALL countries that have admin users
 * but don't have vehicle types configured yet.
 * 
 * Usage: node scripts/initialize-all-country-vehicle-types.js
 */

const database = require('../services/database');

async function initializeAllCountryVehicleTypes() {
    try {
        console.log('🚀 Starting bulk country vehicle types initialization...\n');
        
        // Get all unique countries from admin users
        const countries = await database.query(`
            SELECT DISTINCT country_code, COUNT(*) as admin_count
            FROM admin_users 
            WHERE country_code IS NOT NULL 
            AND role = 'country_admin'
            GROUP BY country_code
            ORDER BY country_code
        `);
        
        console.log(`📍 Found ${countries.rows.length} countries with admin users:`);
        countries.rows.forEach(c => {
            console.log(`   ${c.country_code}: ${c.admin_count} admin(s)`);
        });
        console.log('');
        
        // Get all active vehicle types
        const vehicleTypes = await database.query(
            'SELECT id, name FROM vehicle_types WHERE is_active = true ORDER BY name'
        );
        
        console.log(`🚗 Found ${vehicleTypes.rows.length} active vehicle types:`);
        vehicleTypes.rows.forEach(vt => {
            console.log(`   - ${vt.name} (${vt.id})`);
        });
        console.log('');
        
        if (vehicleTypes.rows.length === 0) {
            console.log('❌ No active vehicle types found. Please add vehicle types first.');
            process.exit(1);
        }
        
        let initialized = 0;
        let skipped = 0;
        
        // Process each country
        for (const country of countries.rows) {
            const countryCode = country.country_code.toUpperCase();
            console.log(`🔄 Processing ${countryCode}...`);
            
            // Check if country already has vehicle types configured
            const existingCount = await database.queryOne(
                'SELECT COUNT(*) as count FROM country_vehicle_types WHERE country_code = $1',
                [countryCode]
            );
            
            if (existingCount.count > 0) {
                console.log(`   ✅ Already configured (${existingCount.count} vehicle types)`);
                skipped++;
                continue;
            }
            
            // Initialize all vehicle types as disabled for this country
            const insertPromises = vehicleTypes.rows.map(vt => 
                database.query(`
                    INSERT INTO country_vehicle_types (vehicle_type_id, country_code, is_active)
                    VALUES ($1, $2, false)
                `, [vt.id, countryCode])
            );
            
            await Promise.all(insertPromises);
            console.log(`   🎉 Initialized ${vehicleTypes.rows.length} vehicle types (all disabled by default)`);
            initialized++;
        }
        
        console.log('\n📊 Summary:');
        console.log(`   Countries initialized: ${initialized}`);
        console.log(`   Countries skipped (already configured): ${skipped}`);
        console.log(`   Total countries processed: ${countries.rows.length}`);
        
        if (initialized > 0) {
            console.log('\n✅ Bulk initialization completed successfully!');
            console.log('💡 Next steps:');
            console.log('   1. Country admins can now log into the admin panel');
            console.log('   2. They can enable/disable vehicle types for their country');
            console.log('   3. Drivers will only see enabled vehicle types in the mobile app');
        } else {
            console.log('\n✅ All countries were already configured!');
        }
        
    } catch (error) {
        console.error('❌ Error during bulk initialization:', error);
        process.exit(1);
    }
}

// Run the script
if (require.main === module) {
    initializeAllCountryVehicleTypes()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error('Script failed:', error);
            process.exit(1);
        });
}

module.exports = { initializeAllCountryVehicleTypes };
