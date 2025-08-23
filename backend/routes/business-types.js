const express = require('express');
const router = express.Router();
const database = require('../services/database');
const auth = require('../services/auth');

// Get all business types for a country (public endpoint for registration form)
router.get('/', async (req, res) => {
  try {
    const { country_code = 'LK' } = req.query;

    const query = `
      SELECT id, name, description, icon, display_order
      FROM business_types 
      WHERE country_code = $1 AND is_active = true
      ORDER BY display_order, name
    `;

    const result = await database.query(query, [country_code]);

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Error fetching business types:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching business types',
      error: error.message
    });
  }
});

// Admin endpoints - require admin authentication
router.use(auth.authMiddleware());

// Check admin permissions
const checkAdminPermission = (req, res, next) => {
  const userRole = req.user.role;
  const userCountry = req.user.country_code;
  
  // Super admins can manage all countries
  if (userRole === 'super_admin') {
    return next();
  }
  
  // Country admins can only manage their own country
  if (userRole === 'admin' || userRole === 'country_admin') {
    req.adminCountry = userCountry; // Restrict to admin's country
    return next();
  }
  
  return res.status(403).json({
    success: false,
    message: 'Admin access required'
  });
};

router.use(checkAdminPermission);

// Get all business types (admin view with all details)
router.get('/admin', async (req, res) => {
  try {
    const { country_code } = req.query;
    const userRole = req.user.role;
    
    let query = `
      SELECT bt.*, 
             cb.display_name as created_by_name,
             ub.display_name as updated_by_name
      FROM business_types bt
      LEFT JOIN admin_users cb ON bt.created_by = cb.id
      LEFT JOIN admin_users ub ON bt.updated_by = ub.id
    `;
    
    const params = [];
    const conditions = [];
    
    // Super admins see all countries, others see only their country
    if (userRole !== 'super_admin') {
      conditions.push('bt.country_code = $1');
      params.push(req.adminCountry || req.user.country_code);
    } else if (country_code) {
      conditions.push('bt.country_code = $1');
      params.push(country_code);
    }
    
    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY bt.country_code, bt.display_order, bt.name';

    const result = await database.query(query, params);

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Error fetching business types (admin):', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching business types',
      error: error.message
    });
  }
});

// Create new business type
router.post('/admin', async (req, res) => {
  try {
    const { name, description, icon, country_code, display_order = 0 } = req.body;
    const userId = req.user.id;
    
    // Validate required fields
    if (!name || !country_code) {
      return res.status(400).json({
        success: false,
        message: 'Name and country_code are required'
      });
    }
    
    // Check if user can manage this country
    if (req.adminCountry && req.adminCountry !== country_code) {
      return res.status(403).json({
        success: false,
        message: 'Cannot manage business types for other countries'
      });
    }

    const insertQuery = `
      INSERT INTO business_types (name, description, icon, country_code, display_order, created_by, updated_by)
      VALUES ($1, $2, $3, $4, $5, $6, $6)
      RETURNING *
    `;

    const result = await database.queryOne(insertQuery, [
      name, description, icon, country_code, display_order, userId
    ]);

    res.status(201).json({
      success: true,
      message: 'Business type created successfully',
      data: result
    });
  } catch (error) {
    console.error('Error creating business type:', error);
    
    if (error.code === '23505') { // Unique constraint violation
      return res.status(400).json({
        success: false,
        message: 'Business type with this name already exists in this country'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Error creating business type',
      error: error.message
    });
  }
});

// Update business type
router.put('/admin/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, icon, is_active, display_order } = req.body;
    const userId = req.user.id;

    // Check if business type exists and user can manage it
    const checkQuery = `
      SELECT * FROM business_types WHERE id = $1
    `;
    
    const existingType = await database.queryOne(checkQuery, [id]);
    
    if (!existingType) {
      return res.status(404).json({
        success: false,
        message: 'Business type not found'
      });
    }
    
    // Check country permission
    if (req.adminCountry && req.adminCountry !== existingType.country_code) {
      return res.status(403).json({
        success: false,
        message: 'Cannot manage business types for other countries'
      });
    }

    const updateQuery = `
      UPDATE business_types 
      SET name = COALESCE($2, name),
          description = COALESCE($3, description),
          icon = COALESCE($4, icon),
          is_active = COALESCE($5, is_active),
          display_order = COALESCE($6, display_order),
          updated_by = $7,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;

    const result = await database.queryOne(updateQuery, [
      id, name, description, icon, is_active, display_order, userId
    ]);

    res.json({
      success: true,
      message: 'Business type updated successfully',
      data: result
    });
  } catch (error) {
    console.error('Error updating business type:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating business type',
      error: error.message
    });
  }
});

// Delete business type (soft delete by setting inactive)
router.delete('/admin/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Check if business type exists and user can manage it
    const checkQuery = `
      SELECT * FROM business_types WHERE id = $1
    `;
    
    const existingType = await database.queryOne(checkQuery, [id]);
    
    if (!existingType) {
      return res.status(404).json({
        success: false,
        message: 'Business type not found'
      });
    }
    
    // Check country permission
    if (req.adminCountry && req.adminCountry !== existingType.country_code) {
      return res.status(403).json({
        success: false,
        message: 'Cannot manage business types for other countries'
      });
    }

    // Check if any businesses are using this type
    const usageCheck = await database.query(
      'SELECT COUNT(*) as count FROM business_verifications WHERE business_type_id = $1',
      [id]
    );

    if (parseInt(usageCheck.rows[0].count) > 0) {
      // Soft delete - deactivate instead of deleting
      const deactivateQuery = `
        UPDATE business_types 
        SET is_active = false, updated_by = $2, updated_at = CURRENT_TIMESTAMP
        WHERE id = $1
        RETURNING *
      `;

      const result = await database.queryOne(deactivateQuery, [id, userId]);

      return res.json({
        success: true,
        message: 'Business type deactivated (cannot delete due to existing usage)',
        data: result
      });
    } else {
      // Hard delete if no usage
      await database.query('DELETE FROM business_types WHERE id = $1', [id]);

      res.json({
        success: true,
        message: 'Business type deleted successfully'
      });
    }
  } catch (error) {
    console.error('Error deleting business type:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting business type',
      error: error.message
    });
  }
});

// Copy business types from one country to another (super admin only)
router.post('/admin/copy', async (req, res) => {
  try {
    if (req.user.role !== 'super_admin') {
      return res.status(403).json({
        success: false,
        message: 'Super admin access required'
      });
    }

    const { from_country, to_country } = req.body;
    const userId = req.user.id;

    if (!from_country || !to_country) {
      return res.status(400).json({
        success: false,
        message: 'from_country and to_country are required'
      });
    }

    // Copy business types
    const copyQuery = `
      INSERT INTO business_types (name, description, icon, country_code, display_order, created_by, updated_by)
      SELECT name, description, icon, $2, display_order, $3, $3
      FROM business_types 
      WHERE country_code = $1 AND is_active = true
      ON CONFLICT (name, country_code) DO NOTHING
      RETURNING *
    `;

    const result = await database.query(copyQuery, [from_country, to_country, userId]);

    res.json({
      success: true,
      message: `Copied ${result.rows.length} business types from ${from_country} to ${to_country}`,
      data: result.rows
    });
  } catch (error) {
    console.error('Error copying business types:', error);
    res.status(500).json({
      success: false,
      message: 'Error copying business types',
      error: error.message
    });
  }
});

module.exports = router;
