const dbService = require('./services/database');
const bcrypt = require('bcryptjs');

async function testFlutterRegistration() {
    try {
        // Safety guard to avoid accidental data creation
        if (process.env.ALLOW_TEST_SCRIPTS !== 'true') {
            console.error('Refusing to run test_flutter_registration: set ALLOW_TEST_SCRIPTS=true to enable.');
            process.exit(1);
        }
        console.log('Testing Flutter registration endpoint...');
        
        // Test the actual registration with same data as Flutter app
        const testData = {
            emailOrPhone: 'cyber.sec.expert@outlook.com',
            firstName: 'Rimas',
            lastName: 'Mohamed',
            displayName: 'Rimas Mohamed',
            password: 'password123',
            isEmail: true
        };
        
        console.log('Test data:', testData);
        
        // Check if user already exists (this might be the issue)
        console.log('\nChecking if user exists...');
        const existingUserResult = await dbService.query(
            'SELECT * FROM users WHERE (email = $1 OR phone = $1)',
            [testData.emailOrPhone]
        );
        
        console.log('Existing users found:', existingUserResult.rows.length);
        if (existingUserResult.rows.length > 0) {
            console.log('Existing user:', existingUserResult.rows[0]);
            console.log('\n⚠️  User already exists! This would cause a 400 error.');
            
            // Let's try with a different email
            testData.emailOrPhone = 'test-' + Date.now() + '@example.com';
            console.log('Trying with new email:', testData.emailOrPhone);
            
            const newCheck = await dbService.query(
                'SELECT * FROM users WHERE (email = $1 OR phone = $1)',
                [testData.emailOrPhone]
            );
            console.log('New email check - existing users:', newCheck.rows.length);
        }
        
        // Hash password
        console.log('\nHashing password...');
        const saltRounds = 12;
        const hashedPassword = await bcrypt.hash(testData.password, saltRounds);
        console.log('Password hashed successfully');
        
        // Create user data
        const userData = {
            email: testData.isEmail ? testData.emailOrPhone : null,
            phone: !testData.isEmail ? testData.emailOrPhone : null,
            first_name: testData.firstName,
            last_name: testData.lastName,
            display_name: testData.displayName,
            password_hash: hashedPassword,
            email_verified: testData.isEmail,
            phone_verified: !testData.isEmail,
            is_active: true,
            role: 'user',
            profile_completed: true
        };
        
        console.log('\nUser data to insert:', userData);
        
        // Try the actual insert with exact same query as flutter endpoint
        console.log('\nTesting user creation...');
        const createUserResult = await dbService.query(
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
        
        console.log('✅ User created successfully!');
        console.log('Created user:', createUserResult.rows[0]);
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error during Flutter registration test:', error);
        console.error('Error message:', error.message);
        console.error('Error code:', error.code);
        console.error('Error detail:', error.detail);
        process.exit(1);
    }
}

testFlutterRegistration();
