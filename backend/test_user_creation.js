const dbService = require('./services/database');

async function testUserCreation() {
    try {
        console.log('Testing user creation with the exact data from Flutter...');
        
        const userData = {
            email: 'cyber.sec.expert@outlook.com',
            phone: null,
            first_name: 'Rimas',
            last_name: 'Mohamed',
            display_name: 'Rimas Mohamed',
            password_hash: 'test_hash',
            email_verified: true,
            phone_verified: false,
            is_active: true,
            role: 'user',
            profile_completed: true
        };

        // Test the exact INSERT query
        const result = await dbService.query(
            `INSERT INTO users (
                id, email, phone, first_name, last_name, display_name, password_hash,
                email_verified, phone_verified, is_active, role, profile_completed, 
                created_at, updated_at
            ) VALUES (
                gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW()
            ) RETURNING *`,
            [
                userData.email, userData.phone, userData.first_name, userData.last_name,
                userData.display_name, userData.password_hash, userData.email_verified,
                userData.phone_verified, userData.is_active, userData.role, userData.profile_completed
            ]
        );
        
        console.log('User creation successful!');
        console.log('Created user:', result.rows[0]);
        
        process.exit(0);
    } catch (error) {
        console.error('User creation failed:', error);
        console.error('Error details:', {
            message: error.message,
            code: error.code,
            detail: error.detail
        });
        process.exit(1);
    }
}

testUserCreation();
