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

// Create a vehicle type
router.post('/', async (req, res) => {
  try {
    const { name, description, icon, capacity, is_active } = req.body || {};
    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'Name is required' });
    }
    const cap = Number.isFinite(capacity) ? capacity : 1;
    const active = typeof is_active === 'boolean' ? is_active : true;

    const insert = await database.query(`
      INSERT INTO vehicle_types (name, description, icon, capacity, is_active)
      VALUES ($1,$2,$3,$4,$5)
      RETURNING *
    `, [name.trim(), description || '', icon || 'DirectionsCar', cap, active]);

    res.status(201).json({ success: true, data: insert.rows[0] });
  } catch (error) {
    console.error('Error creating vehicle type:', error);
    res.status(500).json({ success: false, message: 'Error creating vehicle type', error: error.message });
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

// Update vehicle type
router.put('/:id', async (req, res) => {
  try {
    const id = req.params.id;
    const { name, description, icon, capacity, is_active } = req.body || {};

    const existing = await database.queryOne('SELECT id FROM vehicle_types WHERE id = $1', [id]);
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Vehicle type not found' });
    }

    const update = await database.query(`
      UPDATE vehicle_types
      SET
        name = COALESCE($2, name),
        description = COALESCE($3, description),
        icon = COALESCE($4, icon),
        capacity = COALESCE($5, capacity),
        is_active = COALESCE($6, is_active),
        updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `, [id, name, description, icon, capacity, typeof is_active === 'boolean' ? is_active : null]);

    res.json({ success: true, data: update.rows[0] });
  } catch (error) {
    console.error('Error updating vehicle type:', error);
    res.status(500).json({ success: false, message: 'Error updating vehicle type', error: error.message });
  }
});

// Delete vehicle type
router.delete('/:id', async (req, res) => {
  try {
    const id = req.params.id;
    const deleted = await database.queryOne('DELETE FROM vehicle_types WHERE id = $1 RETURNING *', [id]);
    if (!deleted) {
      return res.status(404).json({ success: false, message: 'Vehicle type not found' });
    }
    res.json({ success: true, data: deleted });
  } catch (error) {
    console.error('Error deleting vehicle type:', error);
    res.status(500).json({ success: false, message: 'Error deleting vehicle type', error: error.message });
  }
});

module.exports = router;
