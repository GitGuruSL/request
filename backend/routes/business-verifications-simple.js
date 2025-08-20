const express = require('express');
const router = express.Router();
const database = require('../services/database');
const auth = require('../services/auth');

console.log('🏢 Simple business verification routes loaded');

// Phone number normalization function
function normalizePhoneNumber(phone) {
  if (!phone) return null;
  // Remove all non-digit characters
  const digitsOnly = phone.replace(/\D/g, '');
  
  // If it starts with country code 94 (Sri Lanka), remove it for comparison
  if (digitsOnly.startsWith('94') && digitsOnly.length > 9) {
    return digitsOnly.substring(2); // Remove '94' prefix
  }
  
  return digitsOnly;
}

// Helper function to check and update phone verification status (unified with driver verification)
async function checkPhoneVerificationStatus(userId, phoneNumber) {
  try {
    // Check if user exists and get current phone status
    const userResult = await database.query(
      'SELECT phone, phone_verified FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      return { phoneVerified: false, needsUpdate: false, requiresManualVerification: true };
    }
    
    const user = userResult.rows[0];
    
    // Normalize phone numbers for comparison
    const normalizedUserPhone = normalizePhoneNumber(user.phone);
    const normalizedPhoneNumber = normalizePhoneNumber(phoneNumber);
    
    // First check user_phone_numbers table for verified phone numbers
    console.log(`📱 Checking user_phone_numbers table for verified phones...`);
    const phoneQuery = `
      SELECT phone_number, is_verified, verified_at, purpose 
      FROM user_phone_numbers 
      WHERE user_id = $1 AND is_verified = true
    `;
    const phoneResult = await database.query(phoneQuery, [userId]);
    
    console.log(`📱 Found ${phoneResult.rows.length} verified phone numbers in user_phone_numbers table`);
    
    // Check against verified phone numbers in user_phone_numbers table
    for (const phoneRecord of phoneResult.rows) {
      const normalizedDbPhone = normalizePhoneNumber(phoneRecord.phone_number);
      console.log(`📱 Comparing: ${normalizedPhoneNumber} === ${normalizedDbPhone} (Purpose: ${phoneRecord.purpose})`);
      
      if (normalizedPhoneNumber === normalizedDbPhone) {
        console.log(`✅ Phone verification match found in user_phone_numbers table!`);
        return { 
          phoneVerified: true, 
          needsUpdate: false, 
          requiresManualVerification: false, 
          verificationSource: 'user_phone_numbers',
          verifiedAt: phoneRecord.verified_at
        };
      }
    }
    
    // If user phone is null but business has phone number, update users table
    if (!user.phone && phoneNumber) {
      await database.query(
        'UPDATE users SET phone = $1, updated_at = NOW() WHERE id = $2',
        [phoneNumber, userId]
      );
      console.log(`📱 Updated user ${userId} phone to ${phoneNumber}`);
      return { phoneVerified: false, needsUpdate: true, requiresManualVerification: true };
    }
    
    // If phone numbers match and user is verified, phone is verified
    if (normalizedUserPhone === normalizedPhoneNumber && user.phone_verified) {
      console.log(`📱 Phone auto-verified: ${normalizedUserPhone} === ${normalizedPhoneNumber}`);
      return { phoneVerified: true, needsUpdate: false, requiresManualVerification: false, verificationSource: 'registration' };
    }
    
    // If phone numbers match but not verified, check OTP verification table
    if (normalizedUserPhone === normalizedPhoneNumber) {
      const otpResult = await database.query(
        'SELECT verified FROM phone_otp_verifications WHERE phone = $1 AND verified = true ORDER BY verified_at DESC LIMIT 1',
        [phoneNumber]
      );
      
      if (otpResult.rows.length > 0) {
        // Update user verification status
        await database.query(
          'UPDATE users SET phone_verified = true, updated_at = NOW() WHERE id = $1',
          [userId]
        );
        console.log(`✅ Auto-verified phone for user ${userId}`);
        return { phoneVerified: true, needsUpdate: true, requiresManualVerification: false, verificationSource: 'otp' };
      }
    }
    
    return { 
      phoneVerified: user.phone_verified || false, 
      needsUpdate: false, 
      requiresManualVerification: !user.phone_verified,
      verificationSource: user.phone_verified ? 'registration' : null
    };
  } catch (error) {
    console.error('Error checking phone verification:', error);
    return { phoneVerified: false, needsUpdate: false, requiresManualVerification: true };
  }
}

async function checkEmailVerificationStatus(userId, email) {
  try {
    console.log(`📧 Checking email verification for user ${userId}, email: ${email}`);
    
    // Check if user exists and get current email status
    const userResult = await database.query(
      'SELECT email, email_verified FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      return { emailVerified: false, needsUpdate: false, requiresManualVerification: true };
    }
    
    const user = userResult.rows[0];
    
    // First check user_email_addresses table for verified emails (professional emails)
    console.log(`📧 Checking user_email_addresses table for verified emails...`);
    const emailQuery = `
      SELECT email_address, is_verified, verified_at, purpose, verification_method 
      FROM user_email_addresses 
      WHERE user_id = $1 AND is_verified = true
    `;
    const emailResult = await database.query(emailQuery, [userId]);
    
    console.log(`📧 Found ${emailResult.rows.length} verified emails in user_email_addresses table`);
    
    // Check against verified emails in user_email_addresses table
    for (const emailRecord of emailResult.rows) {
      console.log(`📧 Comparing: ${email} === ${emailRecord.email_address} (Purpose: ${emailRecord.purpose})`);
      
      if (email.toLowerCase() === emailRecord.email_address.toLowerCase()) {
        console.log(`✅ Email verification match found in user_email_addresses table!`);
        return { 
          emailVerified: true, 
          needsUpdate: false, 
          requiresManualVerification: false, 
          verificationSource: 'user_email_addresses',
          verifiedAt: emailRecord.verified_at,
          verificationMethod: emailRecord.verification_method
        };
      }
    }
    
    // If user email is null but business has email, update users table
    if (!user.email && email) {
      await database.query(
        'UPDATE users SET email = $1, updated_at = NOW() WHERE id = $2',
        [email, userId]
      );
      console.log(`📧 Updated user ${userId} email to ${email}`);
      return { emailVerified: false, needsUpdate: true, requiresManualVerification: true };
    }
    
    // If emails match and user is verified, email is verified
    if (user.email && user.email.toLowerCase() === email.toLowerCase() && user.email_verified) {
      console.log(`📧 Email auto-verified: ${user.email} === ${email}`);
      return { emailVerified: true, needsUpdate: false, requiresManualVerification: false, verificationSource: 'registration' };
    }
    
    // If emails match but not verified, check email verification table
    if (user.email && user.email.toLowerCase() === email.toLowerCase()) {
      const emailVerificationResult = await database.query(
        'SELECT verified FROM email_otp_verifications WHERE email = $1 AND verified = true ORDER BY verified_at DESC LIMIT 1',
        [email]
      );
      
      if (emailVerificationResult.rows.length > 0) {
        // Update user verification status
        await database.query(
          'UPDATE users SET email_verified = true, updated_at = NOW() WHERE id = $1',
          [userId]
        );
        console.log(`✅ Auto-verified email for user ${userId}`);
        return { emailVerified: true, needsUpdate: true, requiresManualVerification: false, verificationSource: 'otp' };
      }
    }
    
    return { 
      emailVerified: user.email_verified || false, 
      needsUpdate: false, 
      requiresManualVerification: !user.email_verified,
      verificationSource: user.email_verified ? 'registration' : null
    };
  } catch (error) {
    console.error('Error checking email verification:', error);
    return { emailVerified: false, needsUpdate: false, requiresManualVerification: true };
  }
}

console.log('🏢 Simple business verification routes loaded');

// Test endpoint
router.get('/test', (req, res) => {
  res.json({
    success: true,
    message: 'Simple business verification routes are working!',
    timestamp: new Date().toISOString()
  });
});

// Create business verification
router.post('/', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    const {
      business_name,
      business_email,
      business_phone,
      business_address,
      business_type,
      registration_number,
      tax_number,
      country_id,
      country_code, // Accept country code as alternative
      city_id,
      description,
      business_license_url,
      tax_certificate_url,
      insurance_document_url,
      business_logo_url
    } = req.body;

    // Use unified verification system (same as driver verification)
    const phoneVerification = await checkPhoneVerificationStatus(userId, business_phone);
    const emailVerification = await checkEmailVerificationStatus(userId, business_email);
    
    console.log(`📞 Phone verification for user ${userId}:`, phoneVerification);
    console.log(`📧 Email verification for user ${userId}:`, emailVerification);

    // Handle country - accept either country_id or country_code
    let finalCountryValue = country_code; // Use country code as text
    if (!finalCountryValue && country_id) {
      // If country_id provided, look up the code
      const countryQuery = 'SELECT code FROM countries WHERE id = $1';
      const countryResult = await database.query(countryQuery, [country_id]);
      if (countryResult.rows.length > 0) {
        finalCountryValue = countryResult.rows[0].code;
      }
    } else if (country_code) {
      // Verify the country code exists
      const countryQuery = 'SELECT code FROM countries WHERE code = $1';
      const countryResult = await database.query(countryQuery, [country_code]);
      if (countryResult.rows.length > 0) {
        finalCountryValue = country_code;
      }
    }

    // Validate required fields
    if (!business_name || !business_email || !business_phone || !finalCountryValue) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: business_name, business_email, business_phone, and country_code'
      });
    }

    // Check if user already has a business verification
    const existingQuery = 'SELECT id FROM business_verifications WHERE user_id = $1';
    const existingResult = await database.query(existingQuery, [userId]);

    if (existingResult.rows.length > 0) {
      // Update existing record
      const updateQuery = `
        UPDATE business_verifications 
        SET business_name = $1, business_email = $2, business_phone = $3, 
            business_address = $4, business_category = $5, license_number = $6, 
            tax_id = $7, country = $8, description = $9,
            business_license_url = $10, tax_certificate_url = $11,
            insurance_document_url = $12, business_logo_url = $13,
            phone_verified = $14, email_verified = $15,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $16
        RETURNING *
      `;
      
      const result = await database.query(updateQuery, [
        business_name, business_email, business_phone, business_address,
        business_type, registration_number, tax_number, finalCountryValue, 
        description, business_license_url, tax_certificate_url,
        insurance_document_url, business_logo_url, phoneVerification.phoneVerified, emailVerification.emailVerified, userId
      ]);

      return res.json({
        success: true,
        message: 'Business verification updated successfully',
        data: result.rows[0],
        verification: {
          phone: phoneVerification,
          email: emailVerification
        }
      });
    } else {
      // Create new record
      const insertQuery = `
        INSERT INTO business_verifications 
        (user_id, business_name, business_email, business_phone, business_address, 
         business_category, license_number, tax_id, country, 
         business_description, business_license_url, tax_certificate_url,
         insurance_document_url, business_logo_url, phone_verified, email_verified, 
         status, submitted_at, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING *
      `;
      
      const result = await database.query(insertQuery, [
        userId, business_name, business_email, business_phone, business_address,
        business_type, registration_number, tax_number, finalCountryValue, 
        description, business_license_url, tax_certificate_url,
        insurance_document_url, business_logo_url, phoneVerification.phoneVerified, emailVerification.emailVerified
      ]);

      return res.json({
        success: true,
        message: 'Business verification submitted successfully',
        data: result.rows[0],
        verification: {
          phone: phoneVerification,
          email: emailVerification
        }
      });
    }

  } catch (error) {
    console.error('Error creating/updating business verification:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Get business verification by user ID
router.get('/user/:userId', auth.authMiddleware(), async (req, res) => {
  try {
    const { userId } = req.params;
    
    const query = `
      SELECT bv.*, 
             c.name as country_name
      FROM business_verifications bv
      LEFT JOIN countries c ON bv.country = c.code
      WHERE bv.user_id = $1
    `;
    
    const result = await database.query(query, [userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No business verification found for this user'
      });
    }

    // Transform data to match admin panel expectations (camelCase)
    const row = result.rows[0];
    const transformedData = {
      ...row,
      // Add camelCase aliases for admin panel
      businessName: row.business_name,
      businessEmail: row.business_email,
      businessPhone: row.business_phone,
      businessAddress: row.business_address,
      businessCategory: row.business_category,
      businessDescription: row.business_description,
      licenseNumber: row.license_number,
      taxId: row.tax_id,
      countryName: row.country_name,
      businessLogoUrl: row.business_logo_url,
      businessLicenseUrl: row.business_license_url,
      insuranceDocumentUrl: row.insurance_document_url,
      taxCertificateUrl: row.tax_certificate_url,
      businessLogoStatus: row.business_logo_status,
      businessLicenseStatus: row.business_license_status,
      insuranceDocumentStatus: row.insurance_document_status,
      taxCertificateStatus: row.tax_certificate_status,
      businessLogoRejectionReason: row.business_logo_rejection_reason,
      businessLicenseRejectionReason: row.business_license_rejection_reason,
      insuranceDocumentRejectionReason: row.insurance_document_rejection_reason,
      taxCertificateRejectionReason: row.tax_certificate_rejection_reason,
      documentVerification: row.document_verification,
      isVerified: row.is_verified,
      phoneVerified: row.phone_verified,
      emailVerified: row.email_verified,
      reviewedBy: row.reviewed_by,
      reviewedDate: row.reviewed_date,
      submittedAt: row.submitted_at,
      approvedAt: row.approved_at,
      lastUpdated: row.last_updated,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };

    res.json({
      success: true,
      data: transformedData
    });

  } catch (error) {
    console.error('Error fetching business verification:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Get all business verifications (for admin panel)
router.get('/', auth.authMiddleware(), async (req, res) => {
  try {
    const { country, status, limit = 50, offset = 0 } = req.query;
    
    let query = `
      SELECT bv.*, 
             c.name as country_name,
             u.first_name, u.last_name, u.email as user_email
      FROM business_verifications bv
      LEFT JOIN countries c ON bv.country = c.code
      LEFT JOIN users u ON bv.user_id = u.id
      WHERE 1=1
    `;
    
    const params = [];
    let paramCount = 0;
    
    // Add filters
    if (country) {
      paramCount++;
      query += ` AND bv.country = $${paramCount}`;
      params.push(country);
    }
    
    if (status && status !== 'all') {
      paramCount++;
      query += ` AND bv.status = $${paramCount}`;
      params.push(status);
    }
    
    // Add ordering and pagination
    query += ` ORDER BY bv.created_at DESC`;
    
    if (limit) {
      paramCount++;
      query += ` LIMIT $${paramCount}`;
      params.push(parseInt(limit));
    }
    
    if (offset) {
      paramCount++;
      query += ` OFFSET $${paramCount}`;
      params.push(parseInt(offset));
    }
    
    const result = await database.query(query, params);

    // Transform data to match admin panel expectations (camelCase)
    const transformedData = result.rows.map(row => ({
      ...row,
      // Add camelCase aliases for admin panel
      businessName: row.business_name,
      businessEmail: row.business_email,
      businessPhone: row.business_phone,
      businessAddress: row.business_address,
      businessCategory: row.business_category,
      businessDescription: row.business_description,
      licenseNumber: row.license_number,
      taxId: row.tax_id,
      countryName: row.country_name,
      businessLogoUrl: row.business_logo_url,
      businessLicenseUrl: row.business_license_url,
      insuranceDocumentUrl: row.insurance_document_url,
      taxCertificateUrl: row.tax_certificate_url,
      businessLogoStatus: row.business_logo_status,
      businessLicenseStatus: row.business_license_status,
      insuranceDocumentStatus: row.insurance_document_status,
      taxCertificateStatus: row.tax_certificate_status,
      businessLogoRejectionReason: row.business_logo_rejection_reason,
      businessLicenseRejectionReason: row.business_license_rejection_reason,
      insuranceDocumentRejectionReason: row.insurance_document_rejection_reason,
      taxCertificateRejectionReason: row.tax_certificate_rejection_reason,
      documentVerification: row.document_verification,
      isVerified: row.is_verified,
      phoneVerified: row.phone_verified,
      emailVerified: row.email_verified,
      reviewedBy: row.reviewed_by,
      reviewedDate: row.reviewed_date,
      submittedAt: row.submitted_at,
      approvedAt: row.approved_at,
      lastUpdated: row.last_updated,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      userEmail: row.user_email,
      firstName: row.first_name,
      lastName: row.last_name
    }));

    res.json({
      success: true,
      data: transformedData,
      count: transformedData.length
    });

  } catch (error) {
    console.error('Error fetching business verifications:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Update business verification status (for admin panel)
router.put('/:id/status', auth.authMiddleware(), async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes, phone_verified, email_verified } = req.body;
    
    const updateQuery = `
      UPDATE business_verifications 
      SET status = $1, notes = $2, phone_verified = $3, email_verified = $4, 
          reviewed_date = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
      WHERE id = $5
      RETURNING *
    `;
    
    const result = await database.query(updateQuery, [
      status, notes, phone_verified, email_verified, id
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business verification not found'
      });
    }

    // Transform data for response
    const row = result.rows[0];
    const transformedData = {
      ...row,
      businessName: row.business_name,
      businessEmail: row.business_email,
      businessPhone: row.business_phone,
      businessAddress: row.business_address,
      businessCategory: row.business_category,
      businessDescription: row.business_description,
      licenseNumber: row.license_number,
      taxId: row.tax_id,
      countryName: row.country_name,
      businessLogoUrl: row.business_logo_url,
      businessLicenseUrl: row.business_license_url,
      insuranceDocumentUrl: row.insurance_document_url,
      taxCertificateUrl: row.tax_certificate_url,
      businessLogoStatus: row.business_logo_status,
      businessLicenseStatus: row.business_license_status,
      insuranceDocumentStatus: row.insurance_document_status,
      taxCertificateStatus: row.tax_certificate_status,
      isVerified: row.is_verified,
      phoneVerified: row.phone_verified,
      emailVerified: row.email_verified,
      reviewedBy: row.reviewed_by,
      reviewedDate: row.reviewed_date,
      submittedAt: row.submitted_at,
      approvedAt: row.approved_at,
      lastUpdated: row.last_updated,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };

    res.json({
      success: true,
      message: 'Business verification status updated successfully',
      data: transformedData
    });

  } catch (error) {
    console.error('Error updating business verification status:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Phone verification endpoints for business verification
router.post('/verify-phone/send-otp', auth.authMiddleware(), async (req, res) => {
  try {
    const { phoneNumber, countryCode } = req.body;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    if (!phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Check if phone is already verified in user_phone_numbers
    const existingPhone = await database.query(
      'SELECT * FROM user_phone_numbers WHERE user_id = $1 AND phone_number = $2 AND is_verified = true',
      [userId, phoneNumber]
    );

    if (existingPhone.rows.length > 0) {
      return res.json({
        success: true,
        message: 'Phone number is already verified',
        already_verified: true
      });
    }

    // Send OTP using country-specific SMS service
    const SMSService = require('../services/smsService');
    const smsService = new SMSService();
    
    // Auto-detect country if not provided
    const detectedCountry = countryCode || smsService.detectCountry(normalizedPhone);
    console.log(`🌍 Using country: ${detectedCountry} for SMS delivery`);

    try {
      const result = await smsService.sendOTP(normalizedPhone, detectedCountry);

      // Store additional metadata for business verification
      await database.query(
        `UPDATE phone_otp_verifications 
         SET user_id = $1, verification_type = 'business_verification'
         WHERE phone = $2 AND otp_id = $3`,
        [userId, normalizedPhone, result.otpId]
      );

      console.log(`✅ OTP sent via ${result.provider} for business verification: ${normalizedPhone}`);

      return res.json({
        success: true,
        message: 'OTP sent successfully',
        phoneNumber: normalizedPhone,
        otpId: result.otpId,
        provider: result.provider,
        countryCode: detectedCountry,
        expiresIn: result.expiresIn
      });
    } catch (error) {
      console.error('SMS service error:', error);
      return res.status(500).json({
        success: false,
        message: error.message || 'Failed to send OTP'
      });
    }

  } catch (error) {
    console.error('Error sending OTP for business verification:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

router.post('/verify-phone/verify-otp', auth.authMiddleware(), async (req, res) => {
  try {
    const { phoneNumber, otp, otpId } = req.body;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    if (!phoneNumber || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and OTP are required'
      });
    }

    // Verify OTP using country-specific SMS service
    const SMSService = require('../services/smsService');
    const smsService = new SMSService();
    
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    console.log(`🔍 Verifying OTP for business verification - Phone: ${phoneNumber} → ${normalizedPhone}, OTP: ${otp}, User: ${userId}`);

    try {
      const verificationResult = await smsService.verifyOTP(normalizedPhone, otp, otpId);

      if (verificationResult.verified) {
        // Auto-detect country for phone number
        const detectedCountry = smsService.detectCountry(normalizedPhone);
        
        // Add verified phone to user_phone_numbers table
        await database.query(`
          INSERT INTO user_phone_numbers (user_id, phone_number, country_code, is_verified, phone_type, purpose, verified_at, created_at)
          VALUES ($1, $2, $3, true, 'professional', 'business_verification', NOW(), NOW())
          ON CONFLICT (user_id, phone_number) 
          DO UPDATE SET is_verified = true, verified_at = NOW(), purpose = 'business_verification', phone_type = 'professional'
        `, [userId, normalizedPhone, detectedCountry]);

        console.log(`✅ Phone verified for business verification: ${normalizedPhone}, stored in user_phone_numbers`);

        return res.json({
          success: true,
          message: 'Phone number verified successfully',
          phoneNumber: normalizedPhone,
          verified: true,
          provider: verificationResult.provider,
          verificationSource: 'user_phone_numbers'
        });
      } else {
        return res.status(400).json({
          success: false,
          message: verificationResult.message || 'Invalid or expired OTP'
        });
      }
    } catch (error) {
      console.error('SMS verification error:', error);
      return res.status(500).json({
        success: false,
        message: error.message || 'Failed to verify OTP'
      });
    }

  } catch (error) {
    console.error('Error verifying OTP for business verification:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
