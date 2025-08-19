const express = require('express');
const router = express.Router();
const database = require('../services/database');

// Get all vehicle types for a country
router.get('/', async (req, res) => {
  try {
    const countryCode = (req.query.country || 'LK').toUpperCase();
    const includeInactive = req.query.includeInactive === 'true';

    const result = await database.query(`
      SELECT 
        vt.id,
        vt.name,
        vt.description,
        vt.icon,
        COALESCE(vt.display_order, 0) AS display_order,
        COALESCE(vt.passenger_capacity, vt.capacity, 1) AS passenger_capacity,
        vt.is_active,
        vt.created_at,
        vt.updated_at,
        cvt.is_active AS country_specific_active,
        COALESCE(cvt.is_active, vt.is_active) AS country_enabled,
        cvt.id AS country_vehicle_type_id
      FROM vehicle_types vt
      LEFT JOIN country_vehicle_types cvt 
        ON vt.id = cvt.vehicle_type_id 
       AND cvt.country_code = $1
      WHERE ($2 OR vt.is_active = true)
      ORDER BY COALESCE(vt.display_order, 9999), vt.name
    `, [countryCode, includeInactive]);

    // Adapt to frontend expected camelCase keys
    const data = result.rows.map(r => ({
      id: r.id,
      name: r.name,
      description: r.description,
      icon: r.icon || 'DirectionsCar',
      displayOrder: r.display_order,
      passengerCapacity: r.passenger_capacity,
      isActive: r.is_active,
      createdAt: r.created_at,
      updatedAt: r.updated_at,
      countryEnabled: r.country_enabled,
      countrySpecificActive: r.country_specific_active,
      countryVehicleTypeId: r.country_vehicle_type_id
    }));

    res.json({ success: true, data });
  } catch (error) {
    console.error('Error fetching vehicle types:', error);
    res.status(500).json({ success: false, message: 'Error fetching vehicle types', error: error.message });
  }
});

// Create a vehicle type
router.post('/', async (req, res) => {
  try {
    const { name, description, icon, capacity, passengerCapacity, displayOrder, is_active, isActive } = req.body || {};
    if (!name || !name.trim()) return res.status(400).json({ success: false, message: 'Name is required' });
    const cap = Number.isFinite(passengerCapacity) ? passengerCapacity : (Number.isFinite(capacity) ? capacity : 1);
    const active = typeof isActive === 'boolean' ? isActive : (typeof is_active === 'boolean' ? is_active : true);
    const orderVal = Number.isFinite(displayOrder) ? displayOrder : null;

    const insert = await database.query(`
      INSERT INTO vehicle_types (name, description, icon, passenger_capacity, display_order, is_active)
      VALUES ($1,$2,$3,$4,$5,$6)
      RETURNING id,name,description,icon,passenger_capacity,display_order,is_active,created_at,updated_at
    `, [name.trim(), description || '', icon || 'DirectionsCar', cap, orderVal, active]);

    const r = insert.rows[0];
    res.status(201).json({ success: true, data: {
      id: r.id,
      name: r.name,
      description: r.description,
      icon: r.icon,
      displayOrder: r.display_order,
      passengerCapacity: r.passenger_capacity,
      isActive: r.is_active,
      createdAt: r.created_at,
      updatedAt: r.updated_at
    }});
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
    const { name, description, icon, capacity, passengerCapacity, displayOrder, is_active, isActive } = req.body || {};
    const existing = await database.queryOne('SELECT id FROM vehicle_types WHERE id = $1', [id]);
    if (!existing) return res.status(404).json({ success: false, message: 'Vehicle type not found' });

    const update = await database.query(`
      UPDATE vehicle_types
      SET
        name = COALESCE($2, name),
        description = COALESCE($3, description),
        icon = COALESCE($4, icon),
        passenger_capacity = COALESCE($5, passenger_capacity),
        display_order = COALESCE($6, display_order),
        is_active = COALESCE($7, is_active),
        updated_at = NOW()
      WHERE id = $1
      RETURNING id,name,description,icon,passenger_capacity,display_order,is_active,created_at,updated_at
    `, [
      id,
      name,
      description,
      icon,
      Number.isFinite(passengerCapacity) ? passengerCapacity : (Number.isFinite(capacity) ? capacity : null),
      Number.isFinite(displayOrder) ? displayOrder : null,
      typeof isActive === 'boolean' ? isActive : (typeof is_active === 'boolean' ? is_active : null)
    ]);

    const r = update.rows[0];
    res.json({ success: true, data: {
      id: r.id,
      name: r.name,
      description: r.description,
      icon: r.icon,
      displayOrder: r.display_order,
      passengerCapacity: r.passenger_capacity,
      isActive: r.is_active,
      createdAt: r.created_at,
      updatedAt: r.updated_at
    }});
  } catch (error) {
    console.error('Error updating vehicle type:', error);
    res.status(500).json({ success: false, message: 'Error updating vehicle type', error: error.message });
  }
});

// Delete vehicle type
router.delete('/:id', async (req, res) => {
  try {
    const id = req.params.id;
    const deleted = await database.queryOne('DELETE FROM vehicle_types WHERE id = $1 RETURNING id,name', [id]);
    if (!deleted) return res.status(404).json({ success: false, message: 'Vehicle type not found' });
    res.json({ success: true, message: 'Vehicle type deleted', data: deleted });
  } catch (error) {
    console.error('Error deleting vehicle type:', error);
    res.status(500).json({ success: false, message: 'Error deleting vehicle type', error: error.message });
  }
});

module.exports = router;
