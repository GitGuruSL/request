const db = require('./services/database');

(async () => {
  try {
    console.log('🔍 Checking OTP/Email configuration...\n');
    
    // 1. Check SMS Provider Configurations
    console.log('1️⃣ SMS Provider Configurations:');
    try {
      const smsConfigs = await db.query('SELECT country_code, provider, is_active, config FROM sms_provider_configs ORDER BY country_code, is_active DESC');
      if (smsConfigs.rows.length > 0) {
        smsConfigs.rows.forEach(config => {
          console.log(`   ${config.country_code}: ${config.provider} (${config.is_active ? 'Active' : 'Inactive'})`);
        });
      } else {
        console.log('   No SMS providers configured');
      }
    } catch (e) {
      console.log('   SMS provider table not accessible:', e.message);
    }
    
    // 2. Check AWS SES Configuration
    console.log('\n2️⃣ AWS SES Configuration Check:');
    console.log(`   AWS_REGION: ${process.env.AWS_REGION || 'Not Set'}`);
    console.log(`   AWS_ACCESS_KEY_ID: ${process.env.AWS_ACCESS_KEY_ID ? 'Set' : 'Not Set'}`);
    console.log(`   AWS_SECRET_ACCESS_KEY: ${process.env.AWS_SECRET_ACCESS_KEY ? 'Set' : 'Not Set'}`);
    console.log(`   AWS_SES_REGION: ${process.env.AWS_SES_REGION || 'Not Set'}`);
    console.log(`   AWS_SES_SOURCE_EMAIL: ${process.env.AWS_SES_SOURCE_EMAIL || 'Not Set'}`);
    
    // 3. Check Recent OTP Requests
    console.log('\n3️⃣ Recent OTP Requests:');
    try {
      const recentOTPs = await db.query(`
        SELECT phone, email, otp_type, status, created_at, expires_at, attempts, last_attempt_at
        FROM phone_verifications 
        WHERE created_at > NOW() - INTERVAL '1 hour'
        ORDER BY created_at DESC 
        LIMIT 10
      `);
      
      if (recentOTPs.rows.length > 0) {
        console.log('   Recent OTP requests (last hour):');
        recentOTPs.rows.forEach(otp => {
          console.log(`   📱 ${otp.phone || otp.email}: ${otp.otp_type} - ${otp.status} (${otp.attempts} attempts)`);
          console.log(`      Created: ${otp.created_at}`);
          console.log(`      Expires: ${otp.expires_at}`);
        });
      } else {
        console.log('   No recent OTP requests found');
      }
    } catch (e) {
      console.log('   OTP table not accessible:', e.message);
    }
    
    // 4. Test AWS SES Connection
    console.log('\n4️⃣ Testing AWS SES Connection:');
    try {
      const { SESClient, GetIdentityVerificationAttributesCommand } = require('@aws-sdk/client-ses');
      
      if (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
        const sesClient = new SESClient({
          region: process.env.AWS_SES_REGION || process.env.AWS_REGION || 'us-east-1',
          credentials: {
            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
          },
        });
        
        if (process.env.AWS_SES_SOURCE_EMAIL) {
          const command = new GetIdentityVerificationAttributesCommand({
            Identities: [process.env.AWS_SES_SOURCE_EMAIL]
          });
          
          const response = await sesClient.send(command);
          const verification = response.VerificationAttributes[process.env.AWS_SES_SOURCE_EMAIL];
          
          if (verification) {
            console.log(`   ✅ Source email verified: ${process.env.AWS_SES_SOURCE_EMAIL}`);
            console.log(`   Status: ${verification.VerificationStatus}`);
          } else {
            console.log(`   ❌ Source email not verified: ${process.env.AWS_SES_SOURCE_EMAIL}`);
          }
        } else {
          console.log('   ⚠️ AWS_SES_SOURCE_EMAIL not configured');
        }
      } else {
        console.log('   ⚠️ AWS credentials not configured');
      }
    } catch (e) {
      console.log(`   ❌ AWS SES connection failed: ${e.message}`);
    }
    
    // 5. Check Email Service
    console.log('\n5️⃣ Email Service Configuration:');
    try {
      const emailService = require('./services/emailService');
      console.log('   📧 Email service loaded successfully');
      
      // Check if nodemailer is configured
      if (emailService.transporter) {
        console.log('   📮 Nodemailer transporter configured');
      } else {
        console.log('   ⚠️ Nodemailer transporter not configured');
      }
    } catch (e) {
      console.log(`   ❌ Email service error: ${e.message}`);
    }
    
    console.log('\n📋 Recommendations:');
    console.log('   1. Verify AWS SES source email is verified in AWS Console');
    console.log('   2. Check AWS credentials have SES permissions');
    console.log('   3. Ensure OTP service is using correct provider for your country');
    console.log('   4. Check application logs for OTP sending errors');
    
  } catch(e) {
    console.error('❌ Error checking OTP configuration:', e.message);
  } finally {
    process.exit(0);
  }
})();
