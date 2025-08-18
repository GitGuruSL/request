const dbService = require('./services/database');

async function checkOtpDetails() {
    try {
        const email = 'cyber.sec.expert@outlook.com';
        
        // Get the most recent OTP token details
        const otpResult = await dbService.query(
            'SELECT * FROM otp_tokens WHERE email_or_phone = $1 ORDER BY created_at DESC LIMIT 1',
            [email]
        );
        
        if (otpResult.rows.length > 0) {
            const otp = otpResult.rows[0];
            console.log('Most recent OTP details:');
            console.log('ID:', otp.id);
            console.log('Email/Phone:', otp.email_or_phone);
            console.log('OTP Code:', otp.otp_code);
            console.log('Token Hash:', otp.token_hash);
            console.log('Created:', otp.created_at);
            console.log('Expires:', otp.expires_at);
            console.log('Used:', otp.used);
            console.log('Attempts:', otp.attempts);
            
            // Check if expired
            const now = new Date();
            const expired = new Date(otp.expires_at) < now;
            console.log('Is Expired:', expired);
        } else {
            console.log('No OTP tokens found');
        }
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkOtpDetails();
