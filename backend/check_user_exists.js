const dbService = require('./services/database');

async function checkUserExists() {
    try {
        const email = 'cyber.sec.expert@outlook.com';
        
        // Check if user exists
        const userResult = await dbService.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );
        
        console.log(`User query result for ${email}:`);
        if (userResult.rows.length > 0) {
            console.log('User found:', userResult.rows[0]);
        } else {
            console.log('No user found with this email');
        }
        
        // Check OTP tokens for this email
        const otpResult = await dbService.query(
            'SELECT * FROM otp_tokens WHERE email_or_phone = $1 ORDER BY created_at DESC LIMIT 5',
            [email]
        );
        
        console.log(`\nOTP tokens for ${email}:`);
        otpResult.rows.forEach((row, index) => {
            console.log(`${index + 1}. Created: ${row.created_at}, Used: ${row.used}, Expires: ${row.expires_at}`);
        });
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkUserExists();
