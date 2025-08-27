const db = require('./services/database');

async function checkSMSConfig() {
  try {
    const result = await db.query("SELECT * FROM sms_configurations WHERE country_code = 'LK'");
    console.log('Sri Lanka SMS Configuration:');
    console.log(JSON.stringify(result.rows[0], null, 2));
    
    // Also check the providers available
    console.log('\nAvailable providers in SMS service:');
    const SMSService = require('./services/smsService');
    console.log(Object.keys(SMSService.providers));
    
    await db.close();
  } catch (error) {
    console.error('Error:', error);
    await db.close();
  }
}

checkSMSConfig();
