const express = require('express');
const router = express.Router();
const database = require('../services/database');
const auth = require('../services/auth');
const { getSignedUrl } = require('../services/s3Upload');

console.log('🔧 Driver verifications route loaded');

// Helper function to normalize phone numbers for consistent comparison
function normalizePhoneNumber(phone) {
  if (!phone) return null;
  // Remove all non-digit characters except +
  let normalized = phone.replace(/[^\d+]/g, '');
  // If starts with +94, keep as is
  if (normalized.startsWith('+94')) {
    return normalized;
  }
  // If starts with 94, add +
  if (normalized.startsWith('94') && normalized.length === 11) {
    return '+' + normalized;
  }
  // If starts with 0, replace with +94
  if (normalized.startsWith('0') && normalized.length === 10) {
    return '+94' + normalized.substring(1);
  }
  // If 9 digits, assume it's without leading 0, add +94
  if (normalized.length === 9) {
    return '+94' + normalized;
  }
  return normalized;
}

// Unified helper function to check and update phone verification status
async function checkPhoneVerificationStatus(userId, phoneNumber) {
  try {
    if (!phoneNumber) {
      return { phoneVerified: false, needsUpdate: false, requiresManualVerification: true };
    }

    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    console.log(`🔍 Checking phone verification for user ${userId}, phone: ${phoneNumber} → ${normalizedPhone}`);

    // 1. Check if phone is verified in driver_verifications table
    const driverResult = await database.query(
      'SELECT phone_verified FROM driver_verifications WHERE user_id = $1 AND phone_number = $2 AND phone_verified = true',
      [userId, normalizedPhone]
    );
    
    if (driverResult.rows.length > 0) {
      console.log(`✅ Phone ${normalizedPhone} is verified in driver_verifications table`);
      return { phoneVerified: true, needsUpdate: false, requiresManualVerification: false, verificationSource: 'driver_verification' };
    }

    // 2. Check if phone is verified in business_verifications table
    const businessResult = await database.query(
      'SELECT phone_verified FROM business_verifications WHERE user_id = $1 AND phone_number = $2 AND phone_verified = true',
      [userId, normalizedPhone]
    );
    
    if (businessResult.rows.length > 0) {
      console.log(`✅ Phone ${normalizedPhone} is verified in business_verifications table`);
      return { phoneVerified: true, needsUpdate: true, requiresManualVerification: false, verificationSource: 'business_verification' };
    }

    // 3. Check if user exists and get personal phone
    const userResult = await database.query(
      'SELECT phone, phone_verified FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      console.log(`❌ User ${userId} not found`);
      return { phoneVerified: false, needsUpdate: false, requiresManualVerification: true };
    }
    
    const user = userResult.rows[0];
    const normalizedUserPhone = normalizePhoneNumber(user.phone);

    // 4. Check if the driver phone matches user's personal phone and it's verified
    if (normalizedPhone === normalizedUserPhone && user.phone_verified === true) {
      console.log(`✅ Driver phone matches verified personal phone: ${normalizedPhone}`);
      return { phoneVerified: true, needsUpdate: true, requiresManualVerification: false, verificationSource: 'personal_phone' };
    }

    // 4. Check if there's any OTP verification history for this phone
    try {
      const otpResult = await database.query(
        'SELECT verified FROM phone_otp_verifications WHERE phone = $1 AND verified = true ORDER BY verified_at DESC LIMIT 1',
        [normalizedPhone]
      );
      
      if (otpResult.rows.length > 0) {
        console.log(`✅ Phone ${normalizedPhone} has verified OTP history - allowing verification`);
        return { phoneVerified: true, needsUpdate: true, requiresManualVerification: false, verificationSource: 'otp_history' };
      }
    } catch (otpError) {
      console.log(`⚠️ Could not check OTP history for ${normalizedPhone}:`, otpError.message);
    }

    // 5. Phone not verified - manual verification required
    console.log(`❌ Phone ${normalizedPhone} not verified - manual verification required`);
    return { phoneVerified: false, needsUpdate: true, requiresManualVerification: true };
  } catch (error) {
    console.error('Error checking phone verification:', error);
    return { phoneVerified: false, needsUpdate: false, requiresManualVerification: true };
  }
}

// Unified helper function to check and update email verification status
async function checkEmailVerificationStatus(userId, email) {
  try {
    if (!email) {
      return { emailVerified: false, needsUpdate: false, requiresManualVerification: true };
    }

    console.log(`🔍 Checking email verification for user ${userId}, email: ${email}`);

    // Get user's current information
    const userResult = await database.query(
      'SELECT email, email_verified FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      console.log(`❌ User ${userId} not found`);
      return { emailVerified: false, needsUpdate: false, requiresManualVerification: true };
    }
    
    const user = userResult.rows[0];
    const normalizedEmail = email.toLowerCase();

    // 1. Check if email is verified in driver_verifications table (priority 1)
    console.log(`📧 Checking driver_verifications table for email verification...`);
    const driverQuery = `
      SELECT email_verified, email_verified_at 
      FROM driver_verifications 
      WHERE user_id = $1 AND LOWER(email) = $2 AND email_verified = true
    `;
    const driverResult = await database.query(driverQuery, [userId, normalizedEmail]);
    
    if (driverResult.rows.length > 0) {
      console.log(`✅ Email verification found in driver_verifications table!`);
      return { 
        emailVerified: true, 
        needsUpdate: false, 
        requiresManualVerification: false, 
        verificationSource: 'driver_verification',
        verifiedAt: driverResult.rows[0].email_verified_at
      };
    }

    // 2. Check if email is verified in business_verifications table (priority 2)
    console.log(`📧 Checking business_verifications table for email verification...`);
    const businessQuery = `
      SELECT email_verified, email_verified_at 
      FROM business_verifications 
      WHERE user_id = $1 AND LOWER(email) = $2 AND email_verified = true
    `;
    const businessResult = await database.query(businessQuery, [userId, normalizedEmail]);
    
    if (businessResult.rows.length > 0) {
      console.log(`✅ Email verification found in business_verifications table!`);
      return { 
        emailVerified: true, 
        needsUpdate: true, 
        requiresManualVerification: false, 
        verificationSource: 'business_verification',
        verifiedAt: businessResult.rows[0].email_verified_at
      };
    }

    // 3. Check if the driver email matches user's personal email and it's verified (priority 3)
    if (user.email && user.email.toLowerCase() === normalizedEmail && user.email_verified) {
      console.log(`✅ Email ${email} verified via users table`);
      return { 
        emailVerified: true, 
        needsUpdate: false, 
        requiresManualVerification: false, 
        verificationSource: 'personal_verification'
      };
    }

    // 4. If user has no email, update it
    if (!user.email && email) {
      await database.query(
        'UPDATE users SET email = $1, updated_at = NOW() WHERE id = $2',
        [email, userId]
      );
      console.log(`📧 Updated user ${userId} email to ${email}`);
      return { emailVerified: false, needsUpdate: true, requiresManualVerification: true };
    }

    // 5. Check email verification table if emails match but not verified
    if (user.email && user.email.toLowerCase() === normalizedEmail) {
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

    console.log(`❌ Email ${email} not verified for user ${userId}`);
    return { 
      emailVerified: false, 
      needsUpdate: false, 
      requiresManualVerification: true,
      verificationSource: null
    };
  } catch (error) {
    console.error('Error checking email verification:', error);
    return { emailVerified: false, needsUpdate: false, requiresManualVerification: true };
  }
}

// Simple test endpoint for Flutter connectivity
router.get('/test', async (req, res) => {
  console.log('📨 Driver verification TEST request received from:', req.headers.origin || 'unknown');
  res.json({
    success: true,
    message: 'Driver verification test endpoint working',
    timestamp: new Date().toISOString()
  });
});

// Get all driver verifications (for admin panel)
router.get('/', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { country = 'LK', status, page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT 
        dv.*,
        c.name as city_display_name,
        vt.name as vehicle_type_display_name
      FROM driver_verifications dv
      LEFT JOIN cities c ON dv.city_id = c.id
      LEFT JOIN vehicle_types vt ON dv.vehicle_type_id = vt.id
      WHERE dv.country = $1
    `;
    
    const queryParams = [country];
    let paramIndex = 2;

    if (status) {
      query += ` AND dv.status = $${paramIndex}`;
      queryParams.push(status);
      paramIndex++;
    }

    query += ` ORDER BY dv.submission_date DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    queryParams.push(limit, offset);

    const result = await database.query(query, queryParams);

    // Transform snake_case to camelCase for frontend compatibility
    const transformedRows = await Promise.all(result.rows.map(async (row) => {
      // Check phone and email verification status for each driver
      const phoneStatus = await checkPhoneVerificationStatus(row.user_id, row.phone_number);
      const emailStatus = await checkEmailVerificationStatus(row.user_id, row.email);
      
      // Parse vehicle image verification JSON (may be array or object)
      let vehicleImageVerification = row.vehicle_image_verification;
      if (typeof vehicleImageVerification === 'string') {
        try { vehicleImageVerification = JSON.parse(vehicleImageVerification); } catch { vehicleImageVerification = null; }
      }
      // Parse vehicle image urls if stored as JSON string
      let vehicleImageUrls = row.vehicle_image_urls;
      if (typeof vehicleImageUrls === 'string' && vehicleImageUrls.trim().startsWith('[')) {
        try { vehicleImageUrls = JSON.parse(vehicleImageUrls); } catch { /* keep original */ }
      }
      
      return {
        ...row,
        fullName: row.full_name,
        firstName: row.first_name,
        lastName: row.last_name,
        phoneNumber: row.phone_number,
        phoneVerified: phoneStatus.phoneVerified,
        phoneVerificationSource: phoneStatus.verificationSource,
        requiresPhoneVerification: phoneStatus.requiresManualVerification,
        emailVerified: emailStatus.emailVerified,
        emailVerificationSource: emailStatus.verificationSource,
        requiresEmailVerification: emailStatus.requiresManualVerification,
        secondaryMobile: row.secondary_mobile,
        nicNumber: row.nic_number,
        dateOfBirth: row.date_of_birth,
        cityId: row.city_id,
        cityName: row.city_name || row.city_display_name,
        vehicleTypeId: row.vehicle_type_id,
        vehicleType: row.vehicle_type_id,  // Add this field for frontend compatibility
        vehicleTypeName: row.vehicle_type_name || row.vehicle_type_display_name,
        vehicleModel: row.vehicle_model,
        vehicleYear: row.vehicle_year,
        vehicleNumber: row.vehicle_number,
        vehicleColor: row.vehicle_color,
        isVehicleOwner: row.is_vehicle_owner,
        licenseNumber: row.license_number,
        licenseExpiry: row.license_expiry,
        licenseHasNoExpiry: row.license_has_no_expiry,
        insuranceNumber: row.insurance_number,
        insuranceExpiry: row.insurance_expiry,
        driverImageUrl: row.driver_image_url,
        nicFrontUrl: row.nic_front_url,
        nicBackUrl: row.nic_back_url,
        licenseFrontUrl: row.license_front_url,
        licenseBackUrl: row.license_back_url,
        licenseDocumentUrl: row.license_document_url,
        vehicleRegistrationUrl: row.vehicle_registration_url,
        insuranceDocumentUrl: row.insurance_document_url,
        billingProofUrl: row.billing_proof_url,
  vehicleImageUrls,
  vehicleImageVerification,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        submissionDate: row.submission_date,
        reviewedDate: row.reviewed_date,
        reviewedBy: row.reviewed_by
      };
    }));

    // Get total count for pagination
    let countQuery = `SELECT COUNT(*) FROM driver_verifications WHERE country = $1`;
    const countParams = [country];
    if (status) {
      countQuery += ` AND status = $2`;
      countParams.push(status);
    }
    
    const countResult = await database.query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: transformedRows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching driver verifications:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch driver verifications',
      error: error.message
    });
  }
});

// Get driver verification by user ID (for mobile app to check status)
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const query = `
      SELECT 
        dv.*,
        c.name as city_display_name,
        vt.name as vehicle_type_display_name
      FROM driver_verifications dv
      LEFT JOIN cities c ON dv.city_id = c.id
      LEFT JOIN vehicle_types vt ON dv.vehicle_type_id = vt.id
      WHERE dv.user_id = $1
      ORDER BY dv.created_at DESC
      LIMIT 1
    `;

    const result = await database.query(query, [userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No driver verification found for this user'
      });
    }

    const row = result.rows[0];
    
    // Check phone and email verification status
    const phoneStatus = await checkPhoneVerificationStatus(row.user_id, row.phone_number);
    const emailStatus = await checkEmailVerificationStatus(row.user_id, row.email);

    // Add verification status to response
    const enrichedData = {
      ...row,
      phoneVerified: phoneStatus.phoneVerified,
      phoneVerificationSource: phoneStatus.verificationSource,
      requiresPhoneVerification: phoneStatus.requiresManualVerification,
      emailVerified: emailStatus.emailVerified,
      emailVerificationSource: emailStatus.verificationSource,
      requiresEmailVerification: emailStatus.requiresManualVerification,
    };

    res.json({
      success: true,
      data: enrichedData
    });
  } catch (error) {
    console.error('Error fetching driver verification by user ID:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch driver verification',
      error: error.message
    });
  }
});

// Phone verification endpoints for driver verification (user endpoints - must come BEFORE parameterized routes)
router.post('/verify-phone/send-otp', auth.authMiddleware(), async (req, res) => {
  try {
    const { phoneNumber, countryCode } = req.body;
    const userId = req.user.id; // Get userId from authenticated user

    if (!phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User authentication required'
      });
    }

    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    console.log(`📱 Sending OTP for driver verification - Phone: ${phoneNumber} → ${normalizedPhone}, User: ${userId}`);

    // Use country-specific SMS service
    const smsService = require('../services/smsService');
    
    // Auto-detect country if not provided
    const detectedCountry = countryCode || smsService.detectCountry(normalizedPhone);
    console.log(`🌍 Using country: ${detectedCountry} for SMS delivery`);

    try {
      // Send OTP using country-specific SMS provider
      const result = await smsService.sendOTP(normalizedPhone, detectedCountry);

      // Store additional metadata for driver verification
      await database.query(
        `UPDATE phone_otp_verifications 
         SET user_id = $1, verification_type = 'driver_verification'
         WHERE phone = $2 AND otp_id = $3`,
        [userId, normalizedPhone, result.otpId]
      );

      console.log(`✅ OTP sent for driver verification - Phone: ${normalizedPhone}, OTP ID: ${result.otpId}, Provider: ${result.provider}`);

      res.json({
        success: true,
        message: 'OTP sent successfully for driver verification',
        otpId: result.otpId,
        phoneNumber: normalizedPhone,
        provider: result.provider,
        expiresAt: result.expiresAt
      });
    } catch (smsError) {
      console.error('❌ SMS Service Error for driver verification:', smsError);
      // Development fallback: auto-generate OTP when no SMS config
      if (process.env.NODE_ENV !== 'production') {
        try {
          const otp = '123456';
          const otpId = `dev_${Date.now()}`;
          await database.query(`
            INSERT INTO phone_otp_verifications 
            (otp_id, phone, otp, country_code, expires_at, attempts, max_attempts, created_at, provider_used)
            VALUES ($1,$2,$3,$4, NOW() + interval '5 minute', 0, 3, NOW(), 'dev_fallback')
          `, [otpId, normalizedPhone, otp, detectedCountry]);
          console.log('🛠 Dev fallback OTP generated (driver): 123456');
          return res.json({
            success: true,
            message: 'DEV MODE: OTP generated (use 123456)',
            phoneNumber: normalizedPhone,
            otpId,
            provider: 'dev_fallback',
            countryCode: detectedCountry,
            devOtp: otp,
            expiresIn: 300
          });
        } catch (e2) {
          console.error('❌ Dev fallback failed:', e2);
        }
      }
      res.status(500).json({
        success: false,
        message: 'Failed to send OTP. Please try again.',
        error: smsError.message
      });
    }
  } catch (error) {
    console.error('❌ Error in driver verification send OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while sending OTP',
      error: error.message
    });
  }
});

router.post('/verify-phone/verify-otp', auth.authMiddleware(), async (req, res) => {
  try {
    const { phoneNumber, otp, otpId } = req.body;
    const userId = req.user.id; // Get userId from authenticated user

    if (!phoneNumber || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and OTP are required'
      });
    }

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User authentication required'
      });
    }

    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    console.log(`🔍 Verifying OTP for driver verification - Phone: ${phoneNumber} → ${normalizedPhone}, OTP: ${otp}, User: ${userId}`);

    // Use country-specific SMS service for verification
    const smsService = require('../services/smsService');
    
    const verificationResult = await smsService.verifyOTP(normalizedPhone, otp, otpId);

    if (verificationResult.verified) {
      // Update driver verification phone verification status
      await database.query(
        'UPDATE driver_verifications SET phone_verified = true WHERE user_id = $1',
        [userId]
      );

      console.log(`✅ Phone verified for driver verification: ${normalizedPhone}, updated driver_verifications table`);

      res.json({
        success: true,
        message: 'Phone verified successfully for driver verification',
        phoneNumber: normalizedPhone,
        verified: true,
        provider: verificationResult.provider,
        verificationSource: 'user_phone_numbers'
      });
    } else {
      res.status(400).json({
        success: false,
        message: verificationResult.message || 'Invalid OTP or expired',
        phoneNumber: normalizedPhone,
        verified: false
      });
    }
  } catch (error) {
    console.error('❌ Error verifying OTP for driver verification:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while verifying OTP',
      error: error.message
    });
  }
});

// Trigger manual phone verification for a driver (ADMIN endpoint)
router.post('/:id/verify-phone', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get driver verification record
    const driverResult = await database.query('SELECT * FROM driver_verifications WHERE id = $1', [id]);
    if (driverResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Driver verification not found' });
    }
    
    const driver = driverResult.rows[0];
    if (!driver.phone_number) {
      return res.status(400).json({ success: false, message: 'Driver has no phone number to verify' });
    }
    
    // Import SMS service
    const SMSManager = require('../services/SMSManager');
    const smsManager = new SMSManager();
    
    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store OTP in database
    await database.query(`
      INSERT INTO phone_otp_verifications (phone, otp, created_at, expires_at, verification_type) 
      VALUES ($1, $2, NOW(), NOW() + INTERVAL '10 minutes', 'driver_verification')
      ON CONFLICT (phone) DO UPDATE SET 
        otp = $2, created_at = NOW(), expires_at = NOW() + INTERVAL '10 minutes', attempts = 0, verified = false
    `, [driver.phone_number, otp]);
    
    // Send SMS
    const smsResult = await smsManager.sendSMS(driver.phone_number, `Your driver verification OTP is: ${otp}. Valid for 10 minutes.`);
    
    if (smsResult.success) {
      res.json({
        success: true,
        message: 'OTP sent successfully',
        phone: driver.phone_number
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send OTP',
        error: smsResult.error
      });
    }
  } catch (error) {
    console.error('Error triggering phone verification:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to trigger phone verification',
      error: error.message
    });
  }
});

// Verify OTP for phone verification
router.post('/:id/verify-otp', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { otp } = req.body;
    
    if (!otp) {
      return res.status(400).json({ success: false, message: 'OTP is required' });
    }
    
    // Get driver verification record
    const driverResult = await database.query('SELECT * FROM driver_verifications WHERE id = $1', [id]);
    if (driverResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Driver verification not found' });
    }
    
    const driver = driverResult.rows[0];
    
    // Verify OTP
    const otpResult = await database.query(`
      SELECT * FROM phone_otp_verifications 
      WHERE phone = $1 AND otp = $2 AND expires_at > NOW() AND verified = false
    `, [driver.phone_number, otp]);
    
    if (otpResult.rows.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid or expired OTP' 
      });
    }
    
    // Mark OTP as verified
    await database.query(`
      UPDATE phone_otp_verifications 
      SET verified = true, verified_at = NOW() 
      WHERE phone = $1 AND otp = $2
    `, [driver.phone_number, otp]);
    
    // Update user verification status
    await database.query(`
      UPDATE users 
      SET phone_verified = true, updated_at = NOW() 
      WHERE id = $1
    `, [driver.user_id]);
    
    res.json({
      success: true,
      message: 'Phone number verified successfully'
    });
  } catch (error) {
    console.error('Error verifying OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify OTP',
      error: error.message
    });
  }
});

// Get single driver verification by ID
router.get('/:id', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      SELECT 
        dv.*,
        c.name as city_display_name,
        vt.name as vehicle_type_display_name
      FROM driver_verifications dv
      LEFT JOIN cities c ON dv.city_id = c.id
      LEFT JOIN vehicle_types vt ON dv.vehicle_type_id = vt.id
      WHERE dv.id = $1
    `;

    const result = await database.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Driver verification not found'
      });
    }

    const row = result.rows[0];
    
    // Check phone and email verification status
    const phoneStatus = await checkPhoneVerificationStatus(row.user_id, row.phone_number);
    const emailStatus = await checkEmailVerificationStatus(row.user_id, row.email);
    
    // Parse document_verification & vehicle_image_verification for convenience
    let documentVerification = row.document_verification;
    if (typeof documentVerification === 'string') {
      try { documentVerification = JSON.parse(documentVerification); } catch { documentVerification = null; }
    }
    let vehicleImageVerification = row.vehicle_image_verification;
    if (typeof vehicleImageVerification === 'string') {
      try { vehicleImageVerification = JSON.parse(vehicleImageVerification); } catch { vehicleImageVerification = null; }
    }
    let vehicleImageUrls = row.vehicle_image_urls;
    if (typeof vehicleImageUrls === 'string' && vehicleImageUrls.trim().startsWith('[')) {
      try { vehicleImageUrls = JSON.parse(vehicleImageUrls); } catch { /* ignore */ }
    }

    // Add verification status to response
    const enrichedData = {
      ...row, 
      document_verification: documentVerification, 
      vehicle_image_verification: vehicleImageVerification, 
      vehicle_image_urls: vehicleImageUrls,
      phoneVerified: phoneStatus.phoneVerified,
      phoneVerificationSource: phoneStatus.verificationSource,
      requiresPhoneVerification: phoneStatus.requiresManualVerification,
      emailVerified: emailStatus.emailVerified,
      emailVerificationSource: emailStatus.verificationSource,
      requiresEmailVerification: emailStatus.requiresManualVerification,
      // Map vehicle type fields for frontend compatibility
      vehicleType: row.vehicle_type_id,
      vehicleTypeName: row.vehicle_type_display_name || row.vehicle_type_name,
      cityName: row.city_display_name || row.city_name,
    };

    console.log(`🚗 Vehicle Type Debug for driver ${id}:`, {
      vehicle_type_id: row.vehicle_type_id,
      vehicle_type_display_name: row.vehicle_type_display_name,
      vehicleType: enrichedData.vehicleType,
      vehicleTypeName: enrichedData.vehicleTypeName
    });

    res.json({
      success: true,
      data: enrichedData
    });
  } catch (error) {
    console.error('Error fetching driver verification:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch driver verification',
      error: error.message
    });
  }
});

// Create new driver verification (from mobile app)
router.post('/', async (req, res) => {
  try {
    console.log('📨 Driver verification POST request received');
    console.log('📤 Request body:', JSON.stringify(req.body, null, 2));
    console.log('📤 Request headers authorization:', req.headers.authorization);
    console.log('📤 Request origin:', req.headers.origin);
    
    const {
      userId,
      fullName,
      firstName,
      lastName,
      dateOfBirth,
      gender,
      nicNumber,
      phoneNumber,
      secondaryMobile,
      email,
      cityId,
      cityName,
      country = 'LK',
      licenseNumber,
      licenseExpiry,
      licenseHasNoExpiry = false,
      vehicleTypeId,
      vehicleTypeName,
      vehicleModel,
      vehicleYear,
      vehicleNumber,
      vehicleColor,
      isVehicleOwner = true,
      insuranceNumber,
      insuranceExpiry,
      driverImageUrl,
      nicFrontUrl,
      nicBackUrl,
      licenseFrontUrl,
      licenseBackUrl,
      licenseDocumentUrl,
      vehicleRegistrationUrl,
      insuranceDocumentUrl,
      billingProofUrl,
      vehicleImageUrls,
      documentVerification,
      vehicleImageVerification,
      subscriptionPlan = 'free',
      notes
    } = req.body;

    // Validate required fields
    if (!userId || !fullName || !dateOfBirth || !gender || !nicNumber || !phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: userId, fullName, dateOfBirth, gender, nicNumber, phoneNumber'
      });
    }

    // Check phone and email verification status using unified system
    console.log('🔍 Checking verification status for driver verification...');
    const phoneStatus = await checkPhoneVerificationStatus(userId, phoneNumber);
    const emailStatus = await checkEmailVerificationStatus(userId, email);
    
    console.log('📱 Phone verification result:', phoneStatus);
    console.log('📧 Email verification result:', emailStatus);

    const query = `
      INSERT INTO driver_verifications (
        user_id, first_name, last_name, full_name, date_of_birth, gender, nic_number,
        phone_number, secondary_mobile, email, city_id, city_name, country,
        license_number, license_expiry, license_has_no_expiry,
        vehicle_type_id, vehicle_type_name, vehicle_model, vehicle_year, vehicle_number, vehicle_color,
        is_vehicle_owner, insurance_number, insurance_expiry,
        driver_image_url, nic_front_url, nic_back_url, license_front_url, license_back_url,
        license_document_url, vehicle_registration_url, insurance_document_url, billing_proof_url,
        vehicle_image_urls, document_verification, vehicle_image_verification,
        subscription_plan, notes, phone_verified, email_verified
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16,
        $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30,
        $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41
      ) RETURNING *
    `;

    const values = [
      userId, firstName, lastName, fullName, dateOfBirth, gender, nicNumber,
      phoneNumber, secondaryMobile, email, cityId, cityName, country,
      licenseNumber, licenseExpiry, licenseHasNoExpiry,
      vehicleTypeId, vehicleTypeName, vehicleModel, vehicleYear, vehicleNumber, vehicleColor,
      isVehicleOwner, insuranceNumber, insuranceExpiry,
      driverImageUrl, nicFrontUrl, nicBackUrl, licenseFrontUrl, licenseBackUrl,
      licenseDocumentUrl, vehicleRegistrationUrl, insuranceDocumentUrl, billingProofUrl,
      vehicleImageUrls ? JSON.stringify(vehicleImageUrls) : null,
      documentVerification ? JSON.stringify(documentVerification) : null,
      vehicleImageVerification ? JSON.stringify(vehicleImageVerification) : null,
      subscriptionPlan, notes, phoneStatus.phoneVerified, emailStatus.emailVerified
    ];

    const result = await database.query(query, values);

    // Add verification status to response
    const responseData = {
      ...result.rows[0],
      phoneVerified: phoneStatus.phoneVerified,
      phoneVerificationSource: phoneStatus.verificationSource,
      phoneType: phoneStatus.phoneType,
      requiresPhoneVerification: phoneStatus.requiresManualVerification,
      emailVerified: emailStatus.emailVerified,
      emailVerificationSource: emailStatus.verificationSource,
      requiresEmailVerification: emailStatus.requiresManualVerification
    };

    console.log('✅ Driver verification submitted with verification status:', {
      phoneVerified: phoneStatus.phoneVerified,
      emailVerified: emailStatus.emailVerified,
      phoneSource: phoneStatus.verificationSource,
      emailSource: emailStatus.verificationSource
    });

    res.status(201).json({
      success: true,
      message: 'Driver verification submitted successfully',
      data: responseData
    });
  } catch (error) {
    console.error('Error creating driver verification:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit driver verification',
      error: error.message
    });
  }
});

// Update driver verification status (admin only)
router.put('/:id/status', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes, reviewedBy } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required'
      });
    }

    // Normalize parameter types to avoid 42P08 (ambiguous inferred types)
    const normalizedStatus = String(status).toLowerCase();
    const normalizedNotes = notes == null ? null : String(notes);
    // reviewedBy may be admin user id (uuid) or null
    const reviewer = reviewedBy && reviewedBy !== 'null' ? reviewedBy : null;
    const numericId = parseInt(id, 10);
    if (Number.isNaN(numericId)) {
      return res.status(400).json({ success:false, message:'Invalid driver verification id'});
    }

    const query = `
      UPDATE driver_verifications 
      SET status = $1::text, notes = $2::text, reviewed_by = $3::uuid, reviewed_date = CURRENT_TIMESTAMP,
          is_verified = CASE WHEN $1::text = 'approved' THEN true ELSE false END
      WHERE id = $4::int
      RETURNING *
    `;

    const result = await database.query(query, [normalizedStatus, normalizedNotes, reviewer, numericId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Driver verification not found'
      });
    }

    const updatedVerification = result.rows[0];

    // If status is approved, update user's role to include driver
    if (status === 'approved' && updatedVerification.user_id) {
      try {
        // Get current user data - cast user_id to UUID to ensure type consistency
        const userQuery = `SELECT * FROM users WHERE id = $1::uuid`;
        const userResult = await database.query(userQuery, [updatedVerification.user_id]);
        
        if (userResult.rows.length > 0) {
          const user = userResult.rows[0];
          let userRoles = [];
          
          // Parse existing roles
          if (user.roles) {
            try {
              userRoles = Array.isArray(user.roles) ? user.roles : JSON.parse(user.roles);
            } catch (e) {
              userRoles = typeof user.roles === 'string' ? [user.roles] : [];
            }
          }
          
          // Add driver role if not already present
          if (!userRoles.includes('driver')) {
            userRoles.push('driver');
            
            // Update user roles - cast user_id to UUID to ensure type consistency
            const updateUserQuery = `
              UPDATE users 
              SET roles = $1, updated_at = CURRENT_TIMESTAMP 
              WHERE id = $2::uuid
            `;
            await database.query(updateUserQuery, [JSON.stringify(userRoles), updatedVerification.user_id]);
            
            console.log(`✅ Added driver role to user ${updatedVerification.user_id}`);
          }
        }
      } catch (roleUpdateError) {
        console.error('Error updating user role:', roleUpdateError);
        // Don't fail the verification update if role update fails
      }
    }

    res.json({
      success: true,
      message: 'Driver verification status updated successfully',
      data: updatedVerification
    });
  } catch (error) {
    console.error('Error updating driver verification status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update driver verification status',
      error: error.message
    });
  }
});

// Update document status (admin only)
router.put('/:id/document-status', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { documentType, status, rejectionReason } = req.body;

    console.log('🔍 Document status update request:', {
      driverId: id,
      documentType,
      status,
      rejectionReason,
      body: req.body
    });

    if (!documentType || !status) {
      console.log('❌ Missing required fields:', { documentType, status });
      return res.status(400).json({
        success: false,
        message: 'Document type and status are required'
      });
    }

    const validDocuments = [
      'driver_image', 'nic_front', 'nic_back', 'license_front', 'license_back',
      'vehicle_registration', 'vehicle_insurance', 'billing_proof'
    ];

    if (!validDocuments.includes(documentType)) {
      console.log('❌ Invalid document type:', documentType, 'Valid types:', validDocuments);
      return res.status(400).json({
        success: false,
        message: `Invalid document type: ${documentType}. Valid types: ${validDocuments.join(', ')}`
      });
    }

    let query = `UPDATE driver_verifications SET ${documentType}_status = $1`;
    const values = [status];
    let paramIndex = 2;

    // Add rejection reason only if column exists (some columns not created for all docs)
    if (rejectionReason && status === 'rejected') {
      const rejectionField = `${documentType}_rejection_reason`;
      // Known existing rejection reason columns (extend if you add more in schema)
      const validRejectionColumns = new Set([
        'license_front_rejection_reason',
        'nic_back_rejection_reason',
        'vehicle_insurance_rejection_reason'
      ]);
      if (validRejectionColumns.has(rejectionField)) {
        query += `, ${rejectionField} = $${paramIndex}`;
        values.push(rejectionReason);
        paramIndex++;
      } else {
        console.log(`ℹ️ Skipping SQL column update for missing rejection column: ${rejectionField}; storing in JSON only`);
      }
    }

    query += ` WHERE id = $${paramIndex} RETURNING *`;
    values.push(id);

    const result = await database.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Driver verification not found'
      });
    }

    // Also update the document_verification JSON field for frontend compatibility
    const driver = result.rows[0];
    let documentVerification = {};
    
    try {
      documentVerification = typeof driver.document_verification === 'string' 
        ? JSON.parse(driver.document_verification) 
        : (driver.document_verification || {});
    } catch (e) {
      documentVerification = {};
    }

    // Map backend document types to frontend camelCase
    const backendToFrontendMap = {
      'driver_image': 'driverImage',
      'nic_front': 'nicFront',
      'nic_back': 'nicBack', 
      'license_front': 'licenseFront',
      'license_back': 'licenseBack',
      'vehicle_registration': 'vehicleRegistration',
      'vehicle_insurance': 'vehicleInsurance',
      'billing_proof': 'billingProof'
    };

    const frontendDocType = backendToFrontendMap[documentType];
    if (frontendDocType) {
      // Update the JSON document verification status
      if (!documentVerification[frontendDocType]) {
        documentVerification[frontendDocType] = {};
      }
      documentVerification[frontendDocType].status = status;
      documentVerification[frontendDocType].reviewedAt = new Date().toISOString();
      if (rejectionReason && status === 'rejected') {
        documentVerification[frontendDocType].rejectionReason = rejectionReason;
      } else if (status !== 'rejected') {
        delete documentVerification[frontendDocType].rejectionReason;
      }

      // Update the database with the new JSON
      await database.query(
        'UPDATE driver_verifications SET document_verification = $1 WHERE id = $2',
        [JSON.stringify(documentVerification), id]
      );

      console.log(`✅ Updated both ${documentType}_status and document_verification.${frontendDocType}.status to "${status}"`);
      
      // Fetch the updated data to return
      const updatedResult = await database.query(
        'SELECT * FROM driver_verifications WHERE id = $1',
        [id]
      );
      
      res.json({
        success: true,
        message: 'Document status updated successfully',
        data: updatedResult.rows[0]
      });
    } else {
      res.json({
        success: true,
        message: 'Document status updated successfully',
        data: result.rows[0]
      });
    }
  } catch (error) {
    console.error('Error updating document status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update document status',
      error: error.message
    });
  }
});

// Update individual vehicle image status (admin only)
router.put('/:id/vehicle-images/:index', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { id, index } = req.params;
    const { status, rejectionReason } = req.body;

    const imageIndex = parseInt(index, 10);
    if (isNaN(imageIndex) || imageIndex < 0) {
      return res.status(400).json({ success: false, message: 'Invalid image index' });
    }
    if (!status) {
      return res.status(400).json({ success: false, message: 'Status is required' });
    }

    // Fetch current record
    const currentResult = await database.query('SELECT id, vehicle_image_urls, vehicle_image_verification FROM driver_verifications WHERE id = $1', [id]);
    if (currentResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Driver verification not found' });
    }
    const driver = currentResult.rows[0];

    // Parse vehicle images array (may be json string)
    let vehicleImageUrls = driver.vehicle_image_urls;
    if (typeof vehicleImageUrls === 'string') {
      try { vehicleImageUrls = JSON.parse(vehicleImageUrls); } catch { /* ignore */ }
    }
    // Optional: validate index does not exceed existing urls length if array
    if (Array.isArray(vehicleImageUrls) && imageIndex >= vehicleImageUrls.length) {
      return res.status(400).json({ success: false, message: 'Image index out of range' });
    }

    // Parse verification object
    let vehicleImageVerification = driver.vehicle_image_verification;
    if (typeof vehicleImageVerification === 'string') {
      try { vehicleImageVerification = JSON.parse(vehicleImageVerification); } catch { vehicleImageVerification = {}; }
    }
    if (!vehicleImageVerification || typeof vehicleImageVerification !== 'object') vehicleImageVerification = {};

    // Update specific image entry
    const existingEntry = vehicleImageVerification[imageIndex] || {};
    vehicleImageVerification[imageIndex] = {
      ...existingEntry,
      status,
      reviewedAt: new Date().toISOString(),
      ...(status === 'rejected' && rejectionReason ? { rejectionReason } : {}),
    };
    if (status !== 'rejected' && vehicleImageVerification[imageIndex].rejectionReason) {
      delete vehicleImageVerification[imageIndex].rejectionReason;
    }

    // Persist JSON only (no per-image columns)
    await database.query('UPDATE driver_verifications SET vehicle_image_verification = $1, updated_at = NOW() WHERE id = $2', [JSON.stringify(vehicleImageVerification), id]);

    // Return updated row
    const updatedResult = await database.query('SELECT * FROM driver_verifications WHERE id = $1', [id]);

    res.json({
      success: true,
      message: 'Vehicle image status updated successfully',
      data: updatedResult.rows[0]
    });
  } catch (error) {
    console.error('Error updating vehicle image status:', error);
    res.status(500).json({ success: false, message: 'Failed to update vehicle image status', error: error.message });
  }
});

// Replace a single document file (driver resubmission) and reset its status to pending
router.put('/:id/replace-document', auth.authMiddleware(), async (req, res) => {
  try {
    const { id } = req.params;
    const { documentType, fileUrl } = req.body;
    if (!documentType || !fileUrl) {
      return res.status(400).json({ success: false, message: 'documentType and fileUrl required' });
    }
    const validDocuments = [
      'driver_image', 'nic_front', 'nic_back', 'license_front', 'license_back',
      'vehicle_registration', 'vehicle_insurance', 'billing_proof', 'license_document'
    ];
    if (!validDocuments.includes(documentType)) {
      return res.status(400).json({ success: false, message: 'Invalid documentType' });
    }
    // Map document types to actual database column names
    const columnMapping = {
      'driver_image': { url: 'driver_image_url', status: 'driver_image_status', rejection: 'driver_image_rejection_reason' },
      'nic_front': { url: 'nic_front_url', status: 'nic_front_status', rejection: 'nic_front_rejection_reason' },
      'nic_back': { url: 'nic_back_url', status: 'nic_back_status', rejection: 'nic_back_rejection_reason' },
      'license_front': { url: 'license_front_url', status: 'license_front_status', rejection: 'license_front_rejection_reason' },
      'license_back': { url: 'license_back_url', status: 'license_back_status', rejection: 'license_back_rejection_reason' },
      'license_document': { url: 'license_document_url', status: 'license_document_status', rejection: 'license_document_rejection_reason' },
      'vehicle_registration': { url: 'vehicle_registration_url', status: 'vehicle_registration_status', rejection: 'vehicle_registration_rejection_reason' },
      'vehicle_insurance': { url: 'insurance_document_url', status: 'vehicle_insurance_status', rejection: 'vehicle_insurance_rejection_reason' },
      'billing_proof': { url: 'billing_proof_url', status: 'billing_proof_status', rejection: 'billing_proof_rejection_reason' }
    };

    const mapping = columnMapping[documentType];
    if (!mapping) {
      return res.status(400).json({ success: false, message: 'Invalid documentType' });
    }

    const urlColumn = mapping.url;
    const statusColumn = mapping.status;
    const rejectionColumn = mapping.rejection;

    // Build dynamic update; some rejection columns don't exist so guard
    let updateSql = `UPDATE driver_verifications SET ${urlColumn} = $1, ${statusColumn} = 'pending', updated_at = NOW()`;
    const values = [fileUrl, id];
    const existingColsRes = await database.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'driver_verifications'");
    const colSet = new Set(existingColsRes.rows.map(r => r.column_name));
    if (colSet.has(rejectionColumn)) {
      updateSql += `, ${rejectionColumn} = NULL`;
    }
    updateSql += ' WHERE id = $2 RETURNING *';
  const result = await database.query(updateSql, values);
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Driver verification not found' });

    // Update JSON document_verification
    const driver = result.rows[0];
    let documentVerification = driver.document_verification;
    if (typeof documentVerification === 'string') { try { documentVerification = JSON.parse(documentVerification); } catch { documentVerification = {}; } }
    const backendToFrontendMap = {
      'driver_image': 'driverImage', 'nic_front': 'nicFront', 'nic_back': 'nicBack',
      'license_front': 'licenseFront', 'license_back': 'licenseBack', 'vehicle_registration': 'vehicleRegistration',
      'vehicle_insurance': 'vehicleInsurance', 'billing_proof': 'billingProof', 'license_document': 'licenseDocument'
    };
    const frontendKey = backendToFrontendMap[documentType];
  if (frontendKey) {
      if (!documentVerification || typeof documentVerification !== 'object') documentVerification = {};
      documentVerification[frontendKey] = {
        ...(documentVerification[frontendKey] || {}),
        status: 'pending',
        rejectionReason: undefined,
        replacedAt: new Date().toISOString(),
        submittedAt: new Date().toISOString()
      };
      await database.query('UPDATE driver_verifications SET document_verification = $1 WHERE id = $2', [JSON.stringify(documentVerification), id]);
    }
  // Audit log
  await database.query('INSERT INTO driver_document_audit (driver_verification_id, user_id, document_type, action, old_url, new_url, metadata) VALUES ($1,$2,$3,$4,$5,$6,$7)', [id, driver.user_id || null, documentType, 'replace_document', driver[urlColumn] || null, fileUrl, JSON.stringify({ via: 'replace-document-endpoint' })]);
    const refreshed = await database.query('SELECT * FROM driver_verifications WHERE id = $1', [id]);
    res.json({ success: true, message: 'Document replaced and reset to pending', data: refreshed.rows[0] });
  } catch (error) {
    console.error('Error replacing document:', error);
    res.status(500).json({ success: false, message: 'Failed to replace document', error: error.message });
  }
});

// Replace a vehicle image by index and reset its status
router.put('/:id/vehicle-images/:index/replace', auth.authMiddleware(), async (req, res) => {
  try {
    const { id, index } = req.params;
    const { fileUrl } = req.body;
    const imageIndex = parseInt(index, 10);
    if (!fileUrl) return res.status(400).json({ success: false, message: 'fileUrl required' });
    if (isNaN(imageIndex) || imageIndex < 0) return res.status(400).json({ success: false, message: 'Invalid index' });
    const rowRes = await database.query('SELECT vehicle_image_urls, vehicle_image_verification FROM driver_verifications WHERE id = $1', [id]);
    if (rowRes.rows.length === 0) return res.status(404).json({ success: false, message: 'Driver verification not found' });
    let urls = rowRes.rows[0].vehicle_image_urls;
    if (typeof urls === 'string') { try { urls = JSON.parse(urls); } catch { urls = []; } }
    if (!Array.isArray(urls)) urls = [];
    // Ensure array large enough
    while (urls.length <= imageIndex) urls.push(null);
    urls[imageIndex] = fileUrl;
    let ver = rowRes.rows[0].vehicle_image_verification;
    if (typeof ver === 'string') { try { ver = JSON.parse(ver); } catch { ver = {}; } }
    if (!ver || typeof ver !== 'object') ver = {};
    ver[imageIndex] = { ...(ver[imageIndex] || {}), status: 'pending', rejectionReason: undefined, replacedAt: new Date().toISOString(), submittedAt: new Date().toISOString() };
  const oldUrl = rowRes.rows[0].vehicle_image_urls;
  await database.query('UPDATE driver_verifications SET vehicle_image_urls = $1, vehicle_image_verification = $2, updated_at = NOW() WHERE id = $3', [JSON.stringify(urls), JSON.stringify(ver), id]);
  await database.query('INSERT INTO driver_document_audit (driver_verification_id, user_id, document_type, action, old_url, new_url, metadata) VALUES ($1,$2,$3,$4,$5,$6,$7)', [id, null, `vehicle_image_${imageIndex}`, 'replace_vehicle_image', Array.isArray(oldUrl)? oldUrl[imageIndex]: null, fileUrl, JSON.stringify({ index: imageIndex })]);
    const updated = await database.query('SELECT * FROM driver_verifications WHERE id = $1', [id]);
    res.json({ success: true, message: 'Vehicle image replaced and reset to pending', data: updated.rows[0] });
  } catch (error) {
    console.error('Error replacing vehicle image:', error);
    res.status(500).json({ success: false, message: 'Failed to replace vehicle image', error: error.message });
  }
});

// Get audit logs for a driver verification (admin only)
router.get('/:id/audit-logs', auth.authMiddleware(), auth.roleMiddleware(['super_admin','country_admin']), async (req,res) => {
  try {
    const { id } = req.params;
    const { documentType, limit = 100 } = req.query;
    const params = [id];
    let sql = `SELECT * FROM driver_document_audit WHERE driver_verification_id = $1`;
    if (documentType) {
      params.push(documentType);
      sql += ` AND document_type = $${params.length}`;
    }
    params.push(limit);
    sql += ` ORDER BY created_at DESC LIMIT $${params.length}`;
    const result = await database.query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching audit logs:', error);
    res.status(500).json({ success:false, message:'Failed to fetch audit logs', error: error.message });
  }
});

// Delete driver verification (admin only)
router.delete('/:id', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { id } = req.params;

    const result = await database.query(
      'DELETE FROM driver_verifications WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Driver verification not found'
      });
    }

    res.json({
      success: true,
      message: 'Driver verification deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting driver verification:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete driver verification',
      error: error.message
    });
  }
});

// Get unified verification status for phone/email (used by driver verification screen)
router.post('/check-verification-status', async (req, res) => {
  try {
    const { phoneNumber, email, userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID is required'
      });
    }

    console.log(`🔍 [Driver] Checking verification status for user ${userId}, phone: ${phoneNumber}, email: ${email}`);

    const result = {
      success: true,
      phoneVerified: false,
      emailVerified: false,
      phoneVerificationSource: null,
      emailVerificationSource: null,
      requiresPhoneOTP: false,
      requiresEmailOTP: false
    };

    // Check phone verification if provided
    if (phoneNumber) {
      const phoneStatus = await checkPhoneVerificationStatus(userId, phoneNumber);
      result.phoneVerified = phoneStatus.phoneVerified;
      result.phoneVerificationSource = phoneStatus.verificationSource;
      result.requiresPhoneOTP = phoneStatus.requiresManualVerification;
      
      console.log(`📱 [Driver] Phone status: verified=${phoneStatus.phoneVerified}, source=${phoneStatus.verificationSource}`);
    }

    // Check email verification if provided
    if (email) {
      const emailStatus = await checkEmailVerificationStatus(userId, email);
      result.emailVerified = emailStatus.emailVerified;
      result.emailVerificationSource = emailStatus.verificationSource;
      result.requiresEmailOTP = emailStatus.requiresManualVerification;
      
      console.log(`📧 [Driver] Email status: verified=${emailStatus.emailVerified}, source=${emailStatus.verificationSource}`);
    }

    res.json(result);
  } catch (error) {
    console.error('Error checking driver verification status:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Get signed URL for document viewing
router.post('/signed-url', async (req, res) => {
  try {
    const { fileUrl } = req.body;
    
    if (!fileUrl) {
      return res.status(400).json({
        success: false,
        message: 'File URL is required'
      });
    }

    console.log('🔗 Generating signed URL for:', fileUrl);
    
    const signedUrl = await getSignedUrl(fileUrl, 3600); // 1 hour expiry
    
    res.json({
      success: true,
      signedUrl: signedUrl
    });
  } catch (error) {
    console.error('❌ Error generating signed URL:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate signed URL',
      error: error.message
    });
  }
});

module.exports = router;
