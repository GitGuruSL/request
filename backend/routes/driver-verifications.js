const express = require('express');
const router = express.Router();
const database = require('../services/database');
const auth = require('../services/auth');
const { getSignedUrl } = require('../services/s3Upload');

console.log('🔧 Driver verifications route loaded');

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
      data: result.rows,
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

    res.json({
      success: true,
      data: result.rows[0]
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

    res.json({
      success: true,
      data: result.rows[0]
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
        subscription_plan, notes
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16,
        $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30,
        $31, $32, $33, $34, $35, $36, $37, $38, $39
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
      subscriptionPlan, notes
    ];

    const result = await database.query(query, values);

    res.status(201).json({
      success: true,
      message: 'Driver verification submitted successfully',
      data: result.rows[0]
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

    const query = `
      UPDATE driver_verifications 
      SET status = $1, notes = $2, reviewed_by = $3, reviewed_date = CURRENT_TIMESTAMP,
          is_verified = CASE WHEN $1 = 'approved' THEN true ELSE false END
      WHERE id = $4
      RETURNING *
    `;

    const result = await database.query(query, [status, notes, reviewedBy, id]);

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
        // Get current user data
        const userQuery = `SELECT * FROM users WHERE id = $1`;
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
            
            // Update user roles
            const updateUserQuery = `
              UPDATE users 
              SET roles = $1, updated_at = CURRENT_TIMESTAMP 
              WHERE id = $2
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

    if (!documentType || !status) {
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
      return res.status(400).json({
        success: false,
        message: 'Invalid document type'
      });
    }

    let query = `UPDATE driver_verifications SET ${documentType}_status = $1`;
    const values = [status];
    let paramIndex = 2;

    // Add rejection reason if provided
    if (rejectionReason && status === 'rejected') {
      const rejectionField = `${documentType}_rejection_reason`;
      query += `, ${rejectionField} = $${paramIndex}`;
      values.push(rejectionReason);
      paramIndex++;
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

    res.json({
      success: true,
      message: 'Document status updated successfully',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating document status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update document status',
      error: error.message
    });
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
