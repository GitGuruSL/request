const db = require('./services/database');

// Import the verification functions from business verifications
const path = require('path');
const fs = require('fs');

// Read the business verification file to get the functions
const businessVerificationFile = fs.readFileSync('./routes/business-verifications.js', 'utf8');

// Extract the normalize phone function
function normalizePhoneNumber(phone) {
  if (!phone) return '';
  return phone.replace(/[^\d]/g, '');
}

async function testNewVerificationSystem() {
  try {
    const userId = '5af58de3-896d-4cc3-bd0b-177054916335';
    const businessPhone = '+94725742238';
    const businessEmail = 'rimaz.m.flyil@gmail.com';
    
    console.log('=== Testing New Verification System ===');
    console.log('User ID:', userId);
    console.log('Business Phone:', businessPhone);
    console.log('Business Email:', businessEmail);
    console.log('');
    
    // Test phone verification
    console.log('=== Phone Verification Test ===');
    
    // Check user_phone_numbers table
    const phoneQuery = `
      SELECT phone_number, is_verified, is_primary, created_at 
      FROM user_phone_numbers 
      WHERE user_id = $1 AND is_verified = true
    `;
    const phoneResult = await db.query(phoneQuery, [userId]);
    console.log('Verified phone numbers in user_phone_numbers:', phoneResult.rows);
    
    // Check user table phone
    const userQuery = 'SELECT phone, phone_verified FROM users WHERE id = $1';
    const userResult = await db.query(userQuery, [userId]);
    console.log('User table phone:', userResult.rows[0]);
    
    // Test normalization
    const normalizedBusiness = normalizePhoneNumber(businessPhone);
    const normalizedUser = normalizePhoneNumber(userResult.rows[0]?.phone);
    console.log('Normalized business phone:', normalizedBusiness);
    console.log('Normalized user phone:', normalizedUser);
    console.log('Phone match:', normalizedBusiness === normalizedUser);
    
    // Test email verification
    console.log('');
    console.log('=== Email Verification Test ===');
    const emailQuery = 'SELECT email, email_verified FROM users WHERE id = $1';
    const emailResult = await db.query(emailQuery, [userId]);
    console.log('User email:', emailResult.rows[0]);
    console.log('Business email:', businessEmail);
    console.log('Email match:', emailResult.rows[0]?.email?.toLowerCase() === businessEmail.toLowerCase());
    console.log('Email verified:', emailResult.rows[0]?.email_verified);
    
  } catch (error) {
    console.error('Error:', error);
  }
  process.exit(0);
}

testNewVerificationSystem();
