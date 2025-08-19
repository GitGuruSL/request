const express = require('express');
const router = express.Router();
const database = require('../services/database');

// Get all vehicle types for a country
router.get('/', async (req, res) => {
  try {
    const countryCode = req.query.country || 'LK';
    
    const result = await database.query(`
      SELECT 
        vt.*, 
        cvt.is_active AS country_specific_active,
        COALESCE(cvt.is_active, vt.is_active) AS country_enabled,
        cvt.id AS country_vehicle_type_id
      FROM vehicle_types vt
      LEFT JOIN country_vehicle_types cvt 
        ON vt.id = cvt.vehicle_type_id 
       AND cvt.country_code = $1
      WHERE vt.is_active = true
      ORDER BY vt.name
    `, [countryCode]);

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Error fetching vehicle types:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching vehicle types',
      error: error.message
    });
  }
});

// Get vehicle type by ID
router.get('/:id', async (req, res) => {
  try {
    const vehicleTypeId = req.params.id;
    
    const vehicleType = await database.queryOne(
      'SELECT * FROM vehicle_types WHERE id = $1',
      [vehicleTypeId]
    );

    if (!vehicleType) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle type not found'
      });
    }

    res.json({
      success: true,
      data: vehicleType
    });
  } catch (error) {
    console.error('Error fetching vehicle type:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching vehicle type',
      error: error.message
    });
  }
});

module.exports = router;
