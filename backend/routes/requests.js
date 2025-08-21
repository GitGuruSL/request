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
      country_code, // no default so super admins (or unspecified) see all countries
      status,
      user_id,
      has_accepted,
      request_type, // Filter by request type: item, service, ride, rent, delivery
      page = 1,
      limit = 20,
      sort_by = 'created_at',
      sort_order = 'DESC'
    } = req.query;

    // Build dynamic query
    const conditions = [];
    const values = [];
    let paramCounter = 1;
    // Default: only active unless explicitly filtering accepted or specifying status
    if (status) {
      conditions.push(`r.status = $${paramCounter++}`);
      values.push(status);
    } else if (has_accepted === 'true') {
      // don't force status; accepted requests are typically closed
    } else {
      conditions.push(`r.status = $${paramCounter++}`);
      values.push('active');
    }

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
    if (request_type) {
      conditions.push(`r.request_type = $${paramCounter++}`);
      values.push(request_type);
    }
  if (country_code) { // only filter when explicitly provided
      conditions.push(`r.country_code = $${paramCounter++}`);
      values.push(country_code);
    }
    if (user_id) {
      conditions.push(`r.user_id = $${paramCounter++}`);
      values.push(user_id);
    }
    if (has_accepted === 'true') {
      conditions.push('r.accepted_response_id IS NOT NULL');
    }

    const offset = (page - 1) * limit;
    const validSortColumns = ['created_at', 'updated_at', 'title', 'budget'];
    const finalSortBy = validSortColumns.includes(sort_by) ? sort_by : 'created_at';
    const finalSortOrder = sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const query = `
      SELECT 
        r.*,
        u.display_name as user_name,
        u.email as user_email,
        c.name as category_name,
        c.request_type as category_request_type,
        sc.name as subcategory_name,
        ct.name as city_name,
        COALESCE(r.country_code, ct.country_code) as effective_country_code,
        co.default_currency as country_default_currency
      FROM requests r
      LEFT JOIN users u ON r.user_id = u.id
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN sub_categories sc ON r.subcategory_id = sc.id
      LEFT JOIN cities ct ON r.location_city_id = ct.id
      LEFT JOIN countries co ON r.country_code = co.code
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

// Search requests by title or description (must come before :id route)
router.get('/search', async (req, res) => {
  try {
    const {
      q,
      category_id,
      subcategory_id,
      city_id,
      country_code,
      status,
      user_id,
  has_accepted,
      page = 1,
      limit = 20,
      sort_by = 'created_at',
      sort_order = 'DESC'
    } = req.query;

    if (!q || String(q).trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Query parameter q is required' });
    }

    const search = `%${q.trim()}%`;

    const conditions = ['(r.title ILIKE $1 OR r.description ILIKE $1)'];
    const values = [search];
    let paramCounter = 2;
    if (status) {
      conditions.push(`r.status = $${paramCounter++}`);
      values.push(status);
    } else if (has_accepted === 'true') {
      // allow closed accepted requests
    } else {
      conditions.push(`r.status = $${paramCounter++}`);
      values.push('active');
    }

    if (category_id) { conditions.push(`r.category_id = $${paramCounter++}`); values.push(category_id); }
    if (subcategory_id) { conditions.push(`r.subcategory_id = $${paramCounter++}`); values.push(subcategory_id); }
    if (city_id) { conditions.push(`r.location_city_id = $${paramCounter++}`); values.push(city_id); }
    if (country_code) { conditions.push(`r.country_code = $${paramCounter++}`); values.push(country_code); }
    if (status) { conditions.push(`r.status = $${paramCounter++}`); values.push(status); }
    if (user_id) { conditions.push(`r.user_id = $${paramCounter++}`); values.push(user_id); }
  if (has_accepted === 'true') { conditions.push('r.accepted_response_id IS NOT NULL'); }

    const offset = (page - 1) * limit;
    const validSortColumns = ['created_at', 'updated_at', 'title', 'budget'];
    const finalSortBy = validSortColumns.includes(sort_by) ? sort_by : 'created_at';
    const finalSortOrder = sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const query = `
      SELECT 
        r.*,
        u.display_name as user_name,
        u.email as user_email,
        c.name as category_name,
        c.request_type as category_request_type,
        sc.name as subcategory_name,
        ct.name as city_name,
        COALESCE(r.country_code, ct.country_code) as effective_country_code,
        co.default_currency as country_default_currency
      FROM requests r
      LEFT JOIN users u ON r.user_id = u.id
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN sub_categories sc ON r.subcategory_id = sc.id
      LEFT JOIN cities ct ON r.location_city_id = ct.id
      LEFT JOIN countries co ON r.country_code = co.code
      WHERE ${conditions.join(' AND ')}
      ORDER BY r.${finalSortBy} ${finalSortOrder}
      LIMIT $${paramCounter++} OFFSET $${paramCounter++}
    `;

    values.push(limit, offset);

    const requests = await database.query(query, values);
    const countQuery = `SELECT COUNT(*) as total FROM requests r WHERE ${conditions.join(' AND ')}`;
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
    console.error('Error searching requests:', error);
    res.status(500).json({ success: false, message: 'Error searching requests', error: error.message });
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
        c.request_type as category_request_type,
        sc.name as subcategory_name,
        ct.name as city_name,
        ar.user_id as accepted_response_user_id,
        COALESCE(r.country_code, ct.country_code) as effective_country_code,
        co.default_currency as country_default_currency
      FROM requests r
      LEFT JOIN users u ON r.user_id = u.id
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN sub_categories sc ON r.subcategory_id = sc.id
      LEFT JOIN cities ct ON r.location_city_id = ct.id
      LEFT JOIN responses ar ON r.accepted_response_id = ar.id
      LEFT JOIN countries co ON r.country_code = co.code
      WHERE r.id = $1
    `, [requestId]);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Request not found'
      });
    }

    // Parse metadata if it exists
    let metadata = {};
    try {
      if (request.metadata) {
        metadata = typeof request.metadata === 'string' 
          ? JSON.parse(request.metadata) 
          : request.metadata;
      }
    } catch (e) {
      console.log('Error parsing metadata:', e);
      metadata = {};
    }

    res.json({
      success: true,
      data: {
        ...request,
        metadata,
        variables: [] // For compatibility with frontend expecting variables array
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
      budget,
      variables = [],
      metadata,
      location_address,
      location_latitude,
      location_longitude,
      currency,
      deadline,
      image_urls,
      request_type // Add request_type field
    } = req.body;

    const user_id = req.user.id;
    const country_code = req.user.country_code || 'LK';

    console.log('=== FULL REQUEST BODY DEBUG ===');
    console.log('Full req.body:', JSON.stringify(req.body, null, 2));
    console.log('metadata field exists?', 'metadata' in req.body);
    console.log('metadata value:', req.body.metadata);
    console.log('metadata type:', typeof req.body.metadata);
    console.log('request_type field:', request_type);
    console.log('=== LOCATION DATA DEBUG ===');
    console.log('location_address:', location_address);
    console.log('location_latitude:', location_latitude);
    console.log('location_longitude:', location_longitude);
    console.log('=== IMAGE DATA DEBUG ===');
    console.log('image_urls:', image_urls);
    console.log('image_urls type:', typeof image_urls);

    console.log('Request creation data:', {
      user_id,
      country_code,
      title,
      description,
      category_id,
      city_id,
      budget,
      request_type,
      metadata: metadata ? JSON.stringify(metadata) : null
    });

    // Validate required fields
    // For ride requests (identified by request_type or metadata), category_id is optional
    const isRideRequest = request_type === 'ride' || 
                          (metadata && 
                           metadata.request_type === 'ride' && 
                           metadata.pickup && 
                           metadata.destination);
    
    if (!title || !description || !city_id) {
      return res.status(400).json({
        success: false,
        message: 'Title, description, and city_id are required'
      });
    }
    
    // Only require category_id for non-ride requests
    if (!isRideRequest && !category_id) {
      return res.status(400).json({
        success: false,
        message: 'Category is required for non-ride requests'
      });
    }

    // Create the request with metadata and request_type
    const request = await database.queryOne(`
      INSERT INTO requests (
        user_id, title, description, category_id, subcategory_id, location_city_id,
        location_address, location_latitude, location_longitude,
        budget, currency, deadline, image_urls, country_code, metadata, request_type, status, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, 'active',
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      ) RETURNING *
    `, [
      user_id, title, description, category_id, subcategory_id, city_id,
      location_address, location_latitude, location_longitude,
      budget, currency, deadline, image_urls, country_code, metadata ? JSON.stringify(metadata) : null, request_type
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
    const userId = req.user.id;
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
      city_id, // client may send city_id; map to location_city_id
      budget_min,
      budget_max,
      budget, // new single budget field
      currency,
      priority,
      status,
      is_active,
      location_address,
      location_latitude,
      location_longitude,
      deadline,
      image_urls,
      metadata
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
      updates.push(`location_city_id = $${paramCounter++}`);
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
    if (budget !== undefined) {
      updates.push(`budget = $${paramCounter++}`);
      values.push(budget);
    }
    if (currency !== undefined) {
      updates.push(`currency = $${paramCounter++}`);
      values.push(currency);
    }
    if (priority !== undefined) {
      updates.push(`priority = $${paramCounter++}`);
      values.push(priority);
    }
    if (status !== undefined) {
      updates.push(`status = $${paramCounter++}`);
      values.push(status);
    }
    if (is_active !== undefined) {
      updates.push(`is_active = $${paramCounter++}`);
      values.push(is_active);
    }
    if (location_address !== undefined) {
      updates.push(`location_address = $${paramCounter++}`);
      values.push(location_address);
    }
    if (location_latitude !== undefined) {
      updates.push(`location_latitude = $${paramCounter++}`);
      values.push(location_latitude);
    }
    if (location_longitude !== undefined) {
      updates.push(`location_longitude = $${paramCounter++}`);
      values.push(location_longitude);
    }
    if (deadline !== undefined) {
      updates.push(`deadline = $${paramCounter++}`);
      values.push(deadline);
    }
    if (image_urls !== undefined) {
      updates.push(`image_urls = $${paramCounter++}`);
      values.push(image_urls);
    }
    if (metadata !== undefined) {
      updates.push(`metadata = $${paramCounter++}`);
      values.push(metadata ? JSON.stringify(metadata) : null);
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
    const userId = req.user.id;
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

// Accept a response (owner only)
router.put('/:id/accept-response', auth.authMiddleware(), async (req, res) => {
  try {
    const requestId = req.params.id;
    const { response_id } = req.body;
    const userId = req.user.id;
    if (!response_id) {
      return res.status(400).json({ success: false, message: 'response_id required' });
    }
    const request = await database.queryOne('SELECT * FROM requests WHERE id=$1', [requestId]);
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });
    if (request.user_id !== userId && req.user.role !== 'admin') return res.status(403).json({ success: false, message: 'Not permitted' });
    // Ensure response belongs to request
    const resp = await database.queryOne('SELECT * FROM responses WHERE id=$1 AND request_id=$2', [response_id, requestId]);
    if (!resp) return res.status(404).json({ success: false, message: 'Response not found for this request' });
  // Auto-close if currently active
  const updated = await database.queryOne("UPDATE requests SET accepted_response_id=$1, status=CASE WHEN status='active' THEN 'closed' ELSE status END, updated_at=NOW() WHERE id=$2 RETURNING *", [response_id, requestId]);
    return res.json({ success: true, message: 'Response accepted', data: updated });
  } catch (error) {
    console.error('Error accepting response:', error);
    res.status(500).json({ success: false, message: 'Error accepting response', error: error.message });
  }
});

// Clear accepted response
router.put('/:id/clear-accepted', auth.authMiddleware(), async (req, res) => {
  try {
    const requestId = req.params.id;
    const userId = req.user.id;
    const request = await database.queryOne('SELECT * FROM requests WHERE id=$1', [requestId]);
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });
    if (request.user_id !== userId && req.user.role !== 'admin') return res.status(403).json({ success: false, message: 'Not permitted' });
  // Re-open if it was closed due to acceptance
  const updated = await database.queryOne("UPDATE requests SET accepted_response_id=NULL, status=CASE WHEN status='closed' THEN 'active' ELSE status END, updated_at=NOW() WHERE id=$1 RETURNING *", [requestId]);
    return res.json({ success: true, message: 'Accepted response cleared', data: updated });
  } catch (error) {
    console.error('Error clearing accepted response:', error);
    res.status(500).json({ success: false, message: 'Error clearing accepted response', error: error.message });
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
    const userId = req.user.id;
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
        c.request_type as category_request_type,
        sc.name as subcategory_name,
        ct.name as city_name,
        COALESCE(r.country_code, ct.country_code) as effective_country_code,
        co.default_currency as country_default_currency
      FROM requests r
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN sub_categories sc ON r.subcategory_id = sc.id
      LEFT JOIN cities ct ON r.location_city_id = ct.id
      LEFT JOIN countries co ON r.country_code = co.code
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
