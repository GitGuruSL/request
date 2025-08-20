const express = require('express');
const router = express.Router();
const database = require('../services/database');
const { auth, requireAuth } = require('../middleware/auth');
const multer = require('multer');
const AWS = require('aws-sdk');

// Configure AWS
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG and WebP are allowed.'));
    }
  }
});

// Helper function to upload file to S3
async function uploadToS3(buffer, fileName, contentType, userId) {
  const key = `business_documents/${userId}/${fileName}`;
  
  const params = {
    Bucket: process.env.AWS_S3_BUCKET || 'requestappbucket',
    Key: key,
    Body: buffer,
    ContentType: contentType,
    ACL: 'public-read'
  };

  const result = await s3.upload(params).promise();
  return result.Location;
}

// Get business verification by user ID
router.get('/user/:userId', requireAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    
    const query = `
      SELECT bv.*, 
             u.first_name, u.last_name, u.email, u.phone_number,
             au.first_name as reviewer_first_name, au.last_name as reviewer_last_name
      FROM business_verifications bv
      LEFT JOIN users u ON bv.user_id = u.id
      LEFT JOIN admin_users au ON bv.reviewed_by = au.id
      WHERE bv.user_id = $1::uuid
    `;
    
    const result = await database.query(query, [userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business verification not found'
      });
    }
    
    const businessVerification = result.rows[0];
    
    // Add contact verification status
    // TODO: This should come from your contact verification service
    businessVerification.phoneVerified = businessVerification.phone_verified || false;
    businessVerification.emailVerified = businessVerification.email_verified || false;
    businessVerification.requiresPhoneVerification = !businessVerification.phoneVerified;
    businessVerification.requiresEmailVerification = !businessVerification.emailVerified;
    
    res.json({
      success: true,
      data: businessVerification
    });
  } catch (error) {
    console.error('Error fetching business verification:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get all business verifications (admin only)
router.get('/', requireAuth, async (req, res) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;
    
    let whereClause = '';
    let queryParams = [];
    
    if (status) {
      whereClause = 'WHERE bv.status = $1';
      queryParams.push(status);
    }
    
    const query = `
      SELECT bv.*, 
             u.first_name, u.last_name, u.email, u.phone_number,
             au.first_name as reviewer_first_name, au.last_name as reviewer_last_name
      FROM business_verifications bv
      LEFT JOIN users u ON bv.user_id = u.id
      LEFT JOIN admin_users au ON bv.reviewed_by = au.id
      ${whereClause}
      ORDER BY bv.submitted_at DESC
      LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}
    `;
    
    queryParams.push(limit, offset);
    
    const result = await database.query(query, queryParams);
    
    // Get total count
    const countQuery = `SELECT COUNT(*) FROM business_verifications bv ${whereClause}`;
    const countResult = await database.query(countQuery, status ? [status] : []);
    const total = parseInt(countResult.rows[0].count);
    
    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching business verifications:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update business verification status (admin only)
router.put('/:id/status', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes, phone_verified, email_verified } = req.body;
    const reviewedBy = req.user?.id;
    
    // Validate status
    if (!['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be pending, approved, or rejected'
      });
    }
    
    // For approval, check if phone and email are verified
    let isVerified = false;
    if (status === 'approved') {
      isVerified = phone_verified === true && email_verified === true;
    }
    
    const query = `
      UPDATE business_verifications 
      SET status = $1::text,
          notes = $2::text,
          reviewed_by = $3::uuid,
          reviewed_date = CURRENT_TIMESTAMP,
          is_verified = $4::boolean,
          phone_verified = $5::boolean,
          email_verified = $6::boolean,
          approved_at = CASE WHEN $1 = 'approved' THEN CURRENT_TIMESTAMP ELSE approved_at END,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $7::int
      RETURNING *
    `;
    
    const result = await database.query(query, [
      status,
      notes || null,
      reviewedBy || null,
      isVerified,
      phone_verified || false,
      email_verified || false,
      id
    ]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business verification not found'
      });
    }
    
    const businessVerification = result.rows[0];
    
    // If approved and verified, add business role to user
    if (status === 'approved' && isVerified) {
      try {
        const userQuery = `
          SELECT roles FROM users WHERE id = $1::uuid
        `;
        const userResult = await database.query(userQuery, [businessVerification.user_id]);
        
        if (userResult.rows.length > 0) {
          let roles = userResult.rows[0].roles || [];
          if (typeof roles === 'string') {
            roles = JSON.parse(roles);
          }
          
          if (!roles.includes('business')) {
            roles.push('business');
            
            const updateUserQuery = `
              UPDATE users 
              SET roles = $1::jsonb,
                  updated_at = CURRENT_TIMESTAMP
              WHERE id = $2::uuid
            `;
            await database.query(updateUserQuery, [JSON.stringify(roles), businessVerification.user_id]);
          }
        }
      } catch (roleError) {
        console.error('Error updating user roles:', roleError);
        // Don't fail the main request if role update fails
      }
    }
    
    res.json({
      success: true,
      data: businessVerification,
      message: `Business verification ${status} successfully`
    });
  } catch (error) {
    console.error('Error updating business verification status:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Create or update business verification
router.post('/', requireAuth, async (req, res) => {
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
      business_category,
      business_description,
      license_number,
      tax_id,
      country = 'LK',
      country_name = 'Sri Lanka',
      business_logo_url,
      business_license_url,
      insurance_document_url,
      tax_certificate_url
    } = req.body;
    
    // Check if verification already exists
    const existingQuery = `SELECT id FROM business_verifications WHERE user_id = $1::uuid`;
    const existingResult = await database.query(existingQuery, [userId]);
    
    let query, params;
    
    if (existingResult.rows.length > 0) {
      // Update existing
      query = `
        UPDATE business_verifications 
        SET business_name = $2,
            business_email = $3,
            business_phone = $4,
            business_address = $5,
            business_category = $6,
            business_description = $7,
            license_number = $8,
            tax_id = $9,
            country = $10,
            country_name = $11,
            business_logo_url = $12,
            business_license_url = $13,
            insurance_document_url = $14,
            tax_certificate_url = $15,
            status = 'pending',
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $1::uuid
        RETURNING *
      `;
      params = [
        userId, business_name, business_email, business_phone, business_address,
        business_category, business_description, license_number, tax_id,
        country, country_name, business_logo_url, business_license_url,
        insurance_document_url, tax_certificate_url
      ];
    } else {
      // Create new
      query = `
        INSERT INTO business_verifications (
          user_id, business_name, business_email, business_phone, business_address,
          business_category, business_description, license_number, tax_id,
          country, country_name, business_logo_url, business_license_url,
          insurance_document_url, tax_certificate_url
        ) VALUES (
          $1::uuid, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
        ) RETURNING *
      `;
      params = [
        userId, business_name, business_email, business_phone, business_address,
        business_category, business_description, license_number, tax_id,
        country, country_name, business_logo_url, business_license_url,
        insurance_document_url, tax_certificate_url
      ];
    }
    
    const result = await database.query(query, params);
    
    res.json({
      success: true,
      data: result.rows[0],
      message: 'Business verification submitted successfully'
    });
  } catch (error) {
    console.error('Error creating/updating business verification:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Upload business document endpoints
router.post('/upload-business-logo', requireAuth, upload.single('businessLogo'), async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const fileName = `business_logo_${Date.now()}.${req.file.originalname.split('.').pop()}`;
    const fileUrl = await uploadToS3(req.file.buffer, fileName, req.file.mimetype, userId);

    // Update business verification record
    const updateQuery = `
      UPDATE business_verifications 
      SET business_logo_url = $1,
          business_logo_status = 'pending',
          updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $2::uuid
    `;
    
    await database.query(updateQuery, [fileUrl, userId]);

    res.json({
      success: true,
      data: {
        url: fileUrl,
        fileName: fileName
      },
      message: 'Business logo uploaded successfully'
    });
  } catch (error) {
    console.error('Error uploading business logo:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload business logo'
    });
  }
});

router.post('/upload-business-license', requireAuth, upload.single('businessLicense'), async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const fileName = `business_license_${Date.now()}.${req.file.originalname.split('.').pop()}`;
    const fileUrl = await uploadToS3(req.file.buffer, fileName, req.file.mimetype, userId);

    // Update business verification record
    const updateQuery = `
      UPDATE business_verifications 
      SET business_license_url = $1,
          business_license_status = 'pending',
          updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $2::uuid
    `;
    
    await database.query(updateQuery, [fileUrl, userId]);

    res.json({
      success: true,
      data: {
        url: fileUrl,
        fileName: fileName
      },
      message: 'Business license uploaded successfully'
    });
  } catch (error) {
    console.error('Error uploading business license:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload business license'
    });
  }
});

router.post('/upload-tax-certificate', requireAuth, upload.single('taxCertificate'), async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const fileName = `tax_certificate_${Date.now()}.${req.file.originalname.split('.').pop()}`;
    const fileUrl = await uploadToS3(req.file.buffer, fileName, req.file.mimetype, userId);

    // Update business verification record
    const updateQuery = `
      UPDATE business_verifications 
      SET tax_certificate_url = $1,
          tax_certificate_status = 'pending',
          updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $2::uuid
    `;
    
    await database.query(updateQuery, [fileUrl, userId]);

    res.json({
      success: true,
      data: {
        url: fileUrl,
        fileName: fileName
      },
      message: 'Tax certificate uploaded successfully'
    });
  } catch (error) {
    console.error('Error uploading tax certificate:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload tax certificate'
    });
  }
});

router.post('/upload-insurance-document', requireAuth, upload.single('insuranceDocument'), async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const fileName = `insurance_document_${Date.now()}.${req.file.originalname.split('.').pop()}`;
    const fileUrl = await uploadToS3(req.file.buffer, fileName, req.file.mimetype, userId);

    // Update business verification record
    const updateQuery = `
      UPDATE business_verifications 
      SET insurance_document_url = $1,
          insurance_document_status = 'pending',
          updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $2::uuid
    `;
    
    await database.query(updateQuery, [fileUrl, userId]);

    res.json({
      success: true,
      data: {
        url: fileUrl,
        fileName: fileName
      },
      message: 'Insurance document uploaded successfully'
    });
  } catch (error) {
    console.error('Error uploading insurance document:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload insurance document'
    });
  }
});

// Phone verification endpoints for business
router.post('/send-phone-otp', requireAuth, async (req, res) => {
  try {
    const { phoneNumber } = req.body;
    const userId = req.user?.id;

    if (!phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // TODO: Integrate with SMS service to send OTP
    // For now, return success to allow testing
    console.log(`📱 Would send OTP to ${phoneNumber} for business verification`);

    res.json({
      success: true,
      message: 'OTP sent successfully',
      verificationId: `business_${userId}_${Date.now()}`
    });
  } catch (error) {
    console.error('Error sending phone OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send OTP'
    });
  }
});

router.post('/verify-phone-otp', requireAuth, async (req, res) => {
  try {
    const { phoneNumber, otp, verificationId } = req.body;
    const userId = req.user?.id;

    if (!phoneNumber || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and OTP are required'
      });
    }

    // TODO: Verify OTP with SMS service
    // For now, accept any 6-digit OTP for testing
    if (otp.length === 6 && /^\d+$/.test(otp)) {
      // Update business verification with phone verification
      const updateQuery = `
        UPDATE business_verifications 
        SET phone_verified = true,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $1::uuid
      `;
      
      await database.query(updateQuery, [userId]);

      // Also update users table
      const userUpdateQuery = `
        UPDATE users 
        SET phone_verified = true,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $1::uuid
      `;
      
      await database.query(userUpdateQuery, [userId]);

      console.log(`✅ Phone verified for business user ${userId}`);

      res.json({
        success: true,
        message: 'Phone number verified successfully'
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }
  } catch (error) {
    console.error('Error verifying phone OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify OTP'
    });
  }
});

// Email verification endpoint for business
router.post('/send-email-verification', requireAuth, async (req, res) => {
  try {
    const { email } = req.body;
    const userId = req.user?.id;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    // TODO: Send verification email
    // For now, return success to allow testing
    console.log(`📧 Would send verification email to ${email} for business verification`);

    res.json({
      success: true,
      message: 'Verification email sent successfully'
    });
  } catch (error) {
    console.error('Error sending verification email:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send verification email'
    });
  }
});

router.post('/verify-email', requireAuth, async (req, res) => {
  try {
    const { email, token } = req.body;
    const userId = req.user?.id;

    if (!email || !token) {
      return res.status(400).json({
        success: false,
        message: 'Email and verification token are required'
      });
    }

    // TODO: Verify email token
    // For now, accept any token for testing
    if (token.length > 0) {
      // Update business verification with email verification
      const updateQuery = `
        UPDATE business_verifications 
        SET email_verified = true,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $1::uuid
      `;
      
      await database.query(updateQuery, [userId]);

      // Also update users table
      const userUpdateQuery = `
        UPDATE users 
        SET email_verified = true,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $1::uuid
      `;
      
      await database.query(userUpdateQuery, [userId]);

      console.log(`✅ Email verified for business user ${userId}`);

      res.json({
        success: true,
        message: 'Email verified successfully'
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Invalid verification token'
      });
    }
  } catch (error) {
    console.error('Error verifying email:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify email'
    });
  }
});

module.exports = router;
