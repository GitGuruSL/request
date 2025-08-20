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
      description
    } = req.body;

    // Handle country - accept either country_id or country_code
    let finalCountryId = country_id;
    if (!finalCountryId && country_code) {
      // Look up country ID by code
      const countryQuery = 'SELECT id FROM countries WHERE code = $1';
      const countryResult = await database.query(countryQuery, [country_code]);
      if (countryResult.rows.length > 0) {
        finalCountryId = countryResult.rows[0].id;
      }
    }

    // Validate required fields
    if (!business_name || !business_email || !business_phone || !finalCountryId) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: business_name, business_email, business_phone, and country_id (or country_code)'
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
            business_address = $4, business_type = $5, registration_number = $6, 
            tax_number = $7, country_id = $8, city_id = $9, description = $10,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $11
        RETURNING *
      `;
      
      const result = await database.query(updateQuery, [
        business_name, business_email, business_phone, business_address,
        business_type, registration_number, tax_number, finalCountryId, 
        city_id, description, userId
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
         business_type, registration_number, tax_number, country_id, city_id, 
         description, status, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING *
      `;
      
      const result = await database.query(insertQuery, [
        userId, business_name, business_email, business_phone, business_address,
        business_type, registration_number, tax_number, finalCountryId, 
        city_id, description
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

    res.json({
      success: true,
      data: result.rows[0]
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

module.exports = router;
