const express = require('express');
const router = express.Router();
const database = require('../services/database');
const auth = require('../services/auth');

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
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $14
        RETURNING *
      `;
      
      const result = await database.query(updateQuery, [
        business_name, business_email, business_phone, business_address,
        business_type, registration_number, tax_number, finalCountryValue, 
        description, business_license_url, tax_certificate_url,
        insurance_document_url, business_logo_url, userId
      ]);

      return res.json({
        success: true,
        message: 'Business verification updated successfully',
        data: result.rows[0]
      });
    } else {
      // Create new record
      const insertQuery = `
        INSERT INTO business_verifications 
        (user_id, business_name, business_email, business_phone, business_address, 
         business_category, license_number, tax_id, country, 
         business_description, business_license_url, tax_certificate_url,
         insurance_document_url, business_logo_url, status, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING *
      `;
      
      const result = await database.query(insertQuery, [
        userId, business_name, business_email, business_phone, business_address,
        business_type, registration_number, tax_number, finalCountryValue, 
        description, business_license_url, tax_certificate_url,
        insurance_document_url, business_logo_url
      ]);

      return res.json({
        success: true,
        message: 'Business verification submitted successfully',
        data: result.rows[0]
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
             c.name as country_name,
             ct.name as city_name
      FROM business_verifications bv
      LEFT JOIN countries c ON bv.country_id = c.id
      LEFT JOIN cities ct ON bv.city_id = ct.id
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

module.exports = router;
