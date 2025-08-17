const express = require('express');
const router = express.Router();
const database = require('../services/database');
const auth = require('../services/auth');
const responsesRouter = require('./responses');

// Get requests with optional filtering
router.get('/', async (req, res) => {
  try {
    const {
      category_id,
      subcategory_id,
      city_id,
      country_code = 'LK',
      status,
      user_id,
      page = 1,
      limit = 20,
      sort_by = 'created_at',
      sort_order = 'DESC'
    } = req.query;

    // Build dynamic query
    const conditions = ['r.status = $1'];
    const values = ['active'];
    let paramCounter = 2;

    if (category_id) {
      conditions.push(`r.category_id = $${paramCounter++}`);
      values.push(category_id);
    }
    if (subcategory_id) {
      conditions.push(`r.subcategory_id = $${paramCounter++}`);
      values.push(subcategory_id);
    }
    if (city_id) {
      conditions.push(`r.location_city_id = $${paramCounter++}`);
      values.push(city_id);
    }
    if (country_code) {
      conditions.push(`r.country_code = $${paramCounter++}`);
      values.push(country_code);
    }
    if (status) {
      conditions.push(`r.status = $${paramCounter++}`);
      values.push(status);
    }
    if (user_id) {
      conditions.push(`r.user_id = $${paramCounter++}`);
      values.push(user_id);
    }

    const offset = (page - 1) * limit;
    const validSortColumns = ['created_at', 'updated_at', 'title', 'budget_min', 'budget_max'];
    const finalSortBy = validSortColumns.includes(sort_by) ? sort_by : 'created_at';
    const finalSortOrder = sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const query = `
      SELECT 
        r.*,
        u.display_name as user_name,
        u.email as user_email,
        c.name as category_name,
        sc.name as subcategory_name,
        ct.name as city_name
      FROM requests r
      LEFT JOIN users u ON r.user_id = u.id
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN subcategories sc ON r.subcategory_id = sc.id
      LEFT JOIN cities ct ON r.location_city_id = ct.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY r.${finalSortBy} ${finalSortOrder}
      LIMIT $${paramCounter++} OFFSET $${paramCounter++}
    `;

    values.push(limit, offset);

    const requests = await database.query(query, values);

    // Get total count for pagination
    const countQuery = `
      SELECT COUNT(*) as total
      FROM requests r
      WHERE ${conditions.join(' AND ')}
    `;
    
    const countResult = await database.queryOne(countQuery, values.slice(0, -2));
    const total = parseInt(countResult.total);

    res.json({
      success: true,
      data: {
        requests: requests.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Error fetching requests:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Error fetching requests',
      error: error.message
    });
  }
});

// Get single request by ID
router.get('/:id', async (req, res) => {
  try {
    const requestId = req.params.id;

    const request = await database.queryOne(`
      SELECT 
        r.*,
        u.display_name as user_name,
        u.email as user_email,
        u.phone as user_phone,
        c.name as category_name,
        sc.name as subcategory_name,
        ct.name as city_name
      FROM requests r
      LEFT JOIN users u ON r.user_id = u.id
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN subcategories sc ON r.subcategory_id = sc.id
      LEFT JOIN cities ct ON r.location_city_id = ct.id
      WHERE r.id = $1
    `, [requestId]);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Request not found'
      });
    }

    // Get request variables if any
    const variablesResult = await database.query(`
      SELECT rv.*, vt.name as variable_name, vt.type as variable_type
      FROM request_variables rv
      LEFT JOIN variable_types vt ON rv.variable_type_id = vt.id
      WHERE rv.request_id = $1
      ORDER BY vt.name
    `, [requestId]);

    res.json({
      success: true,
      data: {
        ...request,
        variables: variablesResult.rows
      }
    });
  } catch (error) {
    console.error('Error fetching request:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching request',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Create new request (requires authentication)
router.post('/', auth.authMiddleware(), async (req, res) => {
  try {
    const {
      title,
      description,
      category_id,
      subcategory_id,
      city_id,
      budget_min,
      budget_max,
      currency = 'LKR',
      priority = 'normal',
      variables = []
    } = req.body;

    const user_id = req.user.userId;
    const country_code = req.user.country_code || 'LK';

    console.log('Request creation data:', {
      user_id,
      country_code,
      title,
      description,
      category_id,
      city_id,
      budget_min,
      budget_max,
      currency,
      priority
    });

    // Validate required fields
    if (!title || !description || !category_id || !city_id) {
      return res.status(400).json({
        success: false,
        message: 'Title, description, category_id, and city_id are required'
      });
    }

    // Create the request
    const request = await database.queryOne(`
      INSERT INTO requests (
        user_id, title, description, category_id, subcategory_id, location_city_id,
        budget_min, budget_max, currency, priority, country_code,
        status, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'active',
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      ) RETURNING *
    `, [
      user_id, title, description, category_id, subcategory_id, city_id,
      budget_min, budget_max, currency, priority, country_code
    ]);

    res.status(201).json({
      success: true,
      message: 'Request created successfully',
      data: request
    });
  } catch (error) {
    console.error('Error creating request:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Error creating request',
      error: error.message // Always show error message for debugging
    });
  }
});

// Update request (requires authentication and ownership)
router.put('/:id', auth.authMiddleware(), async (req, res) => {
  try {
    const requestId = req.params.id;
    const userId = req.user.userId;
    const userRole = req.user.role;

    // Check if request exists and user has permission
    const existingRequest = await database.queryOne(
      'SELECT * FROM requests WHERE id = $1',
      [requestId]
    );

    if (!existingRequest) {
      return res.status(404).json({
        success: false,
        message: 'Request not found'
      });
    }

    // Check ownership or admin role
    if (existingRequest.user_id !== userId && userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'You can only update your own requests'
      });
    }

    const {
      title,
      description,
      category_id,
      subcategory_id,
      city_id,
      budget_min,
      budget_max,
      currency_code,
      urgency_level,
      status,
      is_active
    } = req.body;

    // Build dynamic update query
    const updates = [];
    const values = [];
    let paramCounter = 1;

    if (title !== undefined) {
      updates.push(`title = $${paramCounter++}`);
      values.push(title);
    }
    if (description !== undefined) {
      updates.push(`description = $${paramCounter++}`);
      values.push(description);
    }
    if (category_id !== undefined) {
      updates.push(`category_id = $${paramCounter++}`);
      values.push(category_id);
    }
    if (subcategory_id !== undefined) {
      updates.push(`subcategory_id = $${paramCounter++}`);
      values.push(subcategory_id);
    }
    if (city_id !== undefined) {
      updates.push(`city_id = $${paramCounter++}`);
      values.push(city_id);
    }
    if (budget_min !== undefined) {
      updates.push(`budget_min = $${paramCounter++}`);
      values.push(budget_min);
    }
    if (budget_max !== undefined) {
      updates.push(`budget_max = $${paramCounter++}`);
      values.push(budget_max);
    }
    if (currency_code !== undefined) {
      updates.push(`currency_code = $${paramCounter++}`);
      values.push(currency_code);
    }
    if (urgency_level !== undefined) {
      updates.push(`urgency_level = $${paramCounter++}`);
      values.push(urgency_level);
    }
    if (status !== undefined) {
      updates.push(`status = $${paramCounter++}`);
      values.push(status);
    }
    if (is_active !== undefined) {
      updates.push(`is_active = $${paramCounter++}`);
      values.push(is_active);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid fields to update'
      });
    }

    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(requestId);

    const query = `
      UPDATE requests 
      SET ${updates.join(', ')}
      WHERE id = $${paramCounter}
      RETURNING *
    `;

    const request = await database.queryOne(query, values);

    res.json({
      success: true,
      message: 'Request updated successfully',
      data: request
    });
  } catch (error) {
    console.error('Error updating request:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating request',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Delete request (requires authentication and ownership)
router.delete('/:id', auth.authMiddleware(), async (req, res) => {
  try {
    const requestId = req.params.id;
    const userId = req.user.userId;
    const userRole = req.user.role;

    // Check if request exists and user has permission
    const existingRequest = await database.queryOne(
      'SELECT * FROM requests WHERE id = $1',
      [requestId]
    );

    if (!existingRequest) {
      return res.status(404).json({
        success: false,
        message: 'Request not found'
      });
    }

    // Check ownership or admin role
    if (existingRequest.user_id !== userId && userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own requests'
      });
    }

    const request = await database.queryOne(
      'DELETE FROM requests WHERE id = $1 RETURNING *',
      [requestId]
    );

    res.json({
      success: true,
      message: 'Request deleted successfully',
      data: request
    });
  } catch (error) {
    console.error('Error deleting request:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting request',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Test endpoint for debugging
router.post('/test', auth.authMiddleware(), async (req, res) => {
  try {
    console.log('Test endpoint hit with user:', req.user);
    console.log('Request body:', req.body);
    
    res.json({
      success: true,
      message: 'Test endpoint working',
      user: req.user,
      body: req.body
    });
  } catch (error) {
    console.error('Test endpoint error:', error);
    res.status(500).json({
      success: false,
      message: 'Test endpoint error',
      error: error.message
    });
  }
});

// Get user's own requests
router.get('/user/my-requests', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.userId;
    const { status, page = 1, limit = 20 } = req.query;

    const conditions = ['r.user_id = $1'];
    const values = [userId];
    let paramCounter = 2;

    if (status) {
      conditions.push(`r.status = $${paramCounter++}`);
      values.push(status);
    }

    const offset = (page - 1) * limit;

    const query = `
      SELECT 
        r.*,
        c.name as category_name,
        sc.name as subcategory_name,
        ct.name as city_name
      FROM requests r
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN subcategories sc ON r.subcategory_id = sc.id
      LEFT JOIN cities ct ON r.location_city_id = ct.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY r.created_at DESC
      LIMIT $${paramCounter++} OFFSET $${paramCounter++}
    `;

    values.push(limit, offset);

    const requests = await database.query(query, values);

    // Get total count
    const countQuery = `
      SELECT COUNT(*) as total
      FROM requests r
      WHERE ${conditions.join(' AND ')}
    `;
    
    const countResult = await database.queryOne(countQuery, values.slice(0, -2));
    const total = parseInt(countResult.total);

    res.json({
      success: true,
      data: {
        requests: requests.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Error fetching user requests:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user requests',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

router.use('/:requestId/responses', responsesRouter);

module.exports = router;
