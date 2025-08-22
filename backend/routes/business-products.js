const express = require('express');
const database = require('../services/database');
const auth = require('../services/auth');

const router = express.Router();

// Helper function to format business product data
function formatBusinessProduct(row) {
  if (!row) return null;
  
  return {
    id: row.id,
    businessId: row.business_id,
    masterProductId: row.master_product_id,
    countryCode: row.country_code,
    isActive: row.is_active,
    metadata: row.metadata || {},
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    // Include product details if available
    product: row.product_name ? {
      id: row.master_product_id,
      name: row.product_name,
      slug: row.product_slug,
      baseUnit: row.base_unit,
      brand: row.brand_name ? {
        id: row.brand_id,
        name: row.brand_name
      } : null
    } : null,
    // Include business details if available
    business: row.business_name ? {
      name: row.business_name,
      category: row.business_category,
      isVerified: row.business_verified
    } : null
  };
}

// GET /api/business-products - Get business products with filters
router.get('/', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.uid;
    const userRole = req.user.role;
    
    const { 
      businessId,
      masterProductId,
      country = 'LK',
      includeInactive = 'false',
      search,
      page = 1,
      limit = 20
    } = req.query;

    let whereConditions = [];
    let queryParams = [];
    let paramIndex = 1;

    // Base query
    let query = `
      SELECT 
        bp.*,
        mp.name as product_name,
        mp.slug as product_slug,
        mp.base_unit,
        mp.brand_id,
        b.name as brand_name,
        bv.business_name,
        bv.business_category,
        bv.is_verified as business_verified
      FROM business_products bp
      LEFT JOIN master_products mp ON bp.master_product_id = mp.id
      LEFT JOIN brands b ON mp.brand_id = b.id
      LEFT JOIN new_business_verifications bv ON bp.business_id = bv.user_id
    `;

    // Non-super admin users can only see their own business products
    if (userRole !== 'super_admin') {
      whereConditions.push(`bp.business_id = $${paramIndex}`);
      queryParams.push(userId);
      paramIndex++;
    } else if (businessId) {
      whereConditions.push(`bp.business_id = $${paramIndex}`);
      queryParams.push(businessId);
      paramIndex++;
    }

    if (country) {
      whereConditions.push(`bp.country_code = $${paramIndex}`);
      queryParams.push(country);
      paramIndex++;
    }

    if (includeInactive !== 'true') {
      whereConditions.push(`bp.is_active = true`);
    }

    if (masterProductId) {
      whereConditions.push(`bp.master_product_id = $${paramIndex}`);
      queryParams.push(masterProductId);
      paramIndex++;
    }

    if (search) {
      whereConditions.push(`(mp.name ILIKE $${paramIndex} OR bv.business_name ILIKE $${paramIndex})`);
      queryParams.push(`%${search}%`);
      paramIndex++;
    }

    if (whereConditions.length > 0) {
      query += ` WHERE ${whereConditions.join(' AND ')}`;
    }

    query += ` ORDER BY bp.created_at DESC`;

    // Add pagination
    const offset = (page - 1) * limit;
    query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    queryParams.push(limit, offset);

    console.log('Business products query:', query);
    console.log('Params:', queryParams);

    const result = await database.query(query, queryParams);
    const businessProducts = result.rows.map(formatBusinessProduct);

    // Get total count
    let countQuery = `
      SELECT COUNT(*) as total
      FROM business_products bp
      LEFT JOIN master_products mp ON bp.master_product_id = mp.id
      LEFT JOIN new_business_verifications bv ON bp.business_id = bv.user_id
    `;
    
    if (whereConditions.length > 0) {
      countQuery += ` WHERE ${whereConditions.join(' AND ')}`;
    }

    const countResult = await database.query(countQuery, queryParams.slice(0, -2));
    const total = parseInt(countResult.rows[0].total);

    res.json({
      success: true,
      data: businessProducts,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Error fetching business products:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error fetching business products', 
      error: error.message 
    });
  }
});

// GET /api/business-products/available-products - Get products not yet added by business
router.get('/available-products', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.uid;
    const { 
      search,
      brandId,
      country = 'LK',
      limit = 20
    } = req.query;

    // Verify user is a verified business
    const businessCheck = await database.query(
      'SELECT id FROM new_business_verifications WHERE user_id = $1 AND status = $2',
      [userId, 'approved']
    );

    if (businessCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Only verified businesses can access this endpoint'
      });
    }

    let whereConditions = ['mp.is_active = true'];
    let queryParams = [userId, country];
    let paramIndex = 3;

    let query = `
      SELECT 
        mp.id,
        mp.name,
        mp.slug,
        mp.base_unit,
        b.name as brand_name,
        b.id as brand_id,
        CASE 
          WHEN bp.id IS NOT NULL THEN true 
          ELSE false 
        END as already_added
      FROM master_products mp
      LEFT JOIN brands b ON mp.brand_id = b.id
      LEFT JOIN business_products bp ON mp.id = bp.master_product_id 
        AND bp.business_id = $1 
        AND bp.country_code = $2
    `;

    if (search) {
      whereConditions.push(`mp.name ILIKE $${paramIndex}`);
      queryParams.push(`%${search}%`);
      paramIndex++;
    }

    if (brandId) {
      whereConditions.push(`mp.brand_id = $${paramIndex}`);
      queryParams.push(brandId);
      paramIndex++;
    }

    if (whereConditions.length > 0) {
      query += ` WHERE ${whereConditions.join(' AND ')}`;
    }

    query += ` ORDER BY already_added ASC, mp.name ASC LIMIT $${paramIndex}`;
    queryParams.push(limit);

    const result = await database.query(query, queryParams);
    
    const products = result.rows.map(row => ({
      id: row.id,
      name: row.name,
      slug: row.slug,
      baseUnit: row.base_unit,
      brand: row.brand_name ? {
        id: row.brand_id,
        name: row.brand_name
      } : null,
      alreadyAdded: row.already_added
    }));

    res.json({
      success: true,
      data: products
    });

  } catch (error) {
    console.error('Error fetching available products:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error fetching available products', 
      error: error.message 
    });
  }
});

// GET /api/business-products/:id - Get a specific business product
router.get('/:id', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.uid;
    const userRole = req.user.role;
    const { id } = req.params;

    let query = `
      SELECT 
        bp.*,
        mp.name as product_name,
        mp.slug as product_slug,
        mp.base_unit,
        mp.brand_id,
        b.name as brand_name,
        bv.business_name,
        bv.business_category,
        bv.is_verified as business_verified
      FROM business_products bp
      LEFT JOIN master_products mp ON bp.master_product_id = mp.id
      LEFT JOIN brands b ON mp.brand_id = b.id
      LEFT JOIN new_business_verifications bv ON bp.business_id = bv.user_id
      WHERE bp.id = $1
    `;

    let queryParams = [id];

    // Non-super admin users can only see their own business products
    if (userRole !== 'super_admin') {
      query += ` AND bp.business_id = $2`;
      queryParams.push(userId);
    }

    const result = await database.query(query, queryParams);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business product not found'
      });
    }

    const businessProduct = formatBusinessProduct(result.rows[0]);

    res.json({
      success: true,
      data: businessProduct
    });

  } catch (error) {
    console.error('Error fetching business product:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error fetching business product', 
      error: error.message 
    });
  }
});

// POST /api/business-products - Add a product to business (Business users only)
router.post('/', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.uid;
    
    // Verify user is a verified business
    const businessCheck = await database.query(
      'SELECT id FROM new_business_verifications WHERE user_id = $1 AND status = $2',
      [userId, 'approved']
    );

    if (businessCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Only verified businesses can add products'
      });
    }

    const {
      masterProductId,
      countryCode = 'LK',
      metadata = {},
      isActive = true
    } = req.body;

    if (!masterProductId) {
      return res.status(400).json({
        success: false,
        message: 'Master product ID is required'
      });
    }

    // Verify master product exists
    const productCheck = await database.query(
      'SELECT id FROM master_products WHERE id = $1 AND is_active = true',
      [masterProductId]
    );

    if (productCheck.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or inactive master product'
      });
    }

    // Check if business already has this product
    const existingProduct = await database.query(
      'SELECT id FROM business_products WHERE business_id = $1 AND master_product_id = $2 AND country_code = $3',
      [userId, masterProductId, countryCode]
    );

    if (existingProduct.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'This product is already added to your business'
      });
    }

    // Create business product
    const insertQuery = `
      INSERT INTO business_products (business_id, master_product_id, country_code, metadata, is_active)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;

    const values = [userId, masterProductId, countryCode, JSON.stringify(metadata), isActive];
    const result = await database.query(insertQuery, values);

    // Get the full product details
    const detailQuery = `
      SELECT 
        bp.*,
        mp.name as product_name,
        mp.slug as product_slug,
        mp.base_unit,
        mp.brand_id,
        b.name as brand_name
      FROM business_products bp
      LEFT JOIN master_products mp ON bp.master_product_id = mp.id
      LEFT JOIN brands b ON mp.brand_id = b.id
      WHERE bp.id = $1
    `;

    const detailResult = await database.query(detailQuery, [result.rows[0].id]);
    const businessProduct = formatBusinessProduct(detailResult.rows[0]);

    res.status(201).json({
      success: true,
      message: 'Product added to business successfully',
      data: businessProduct
    });

  } catch (error) {
    console.error('Error adding business product:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error adding business product', 
      error: error.message 
    });
  }
});

// PUT /api/business-products/:id - Update a business product
router.put('/:id', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.uid;
    const userRole = req.user.role;
    const { id } = req.params;

    // Check if business product exists and user has permission
    let checkQuery = 'SELECT * FROM business_products WHERE id = $1';
    let checkParams = [id];

    if (userRole !== 'super_admin') {
      checkQuery += ' AND business_id = $2';
      checkParams.push(userId);
    }

    const existing = await database.query(checkQuery, checkParams);
    
    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business product not found or you do not have permission to edit it'
      });
    }

    const { metadata, isActive } = req.body;

    // Build update query
    const updateFields = [];
    const updateValues = [];
    let paramIndex = 1;

    if (metadata !== undefined) {
      updateFields.push(`metadata = $${paramIndex}`);
      updateValues.push(JSON.stringify(metadata));
      paramIndex++;
    }

    if (isActive !== undefined) {
      updateFields.push(`is_active = $${paramIndex}`);
      updateValues.push(isActive);
      paramIndex++;
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update'
      });
    }

    updateFields.push(`updated_at = NOW()`);

    const updateQuery = `
      UPDATE business_products 
      SET ${updateFields.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING *
    `;
    
    updateValues.push(id);

    const result = await database.query(updateQuery, updateValues);

    // Get the full product details
    const detailQuery = `
      SELECT 
        bp.*,
        mp.name as product_name,
        mp.slug as product_slug,
        mp.base_unit,
        mp.brand_id,
        b.name as brand_name
      FROM business_products bp
      LEFT JOIN master_products mp ON bp.master_product_id = mp.id
      LEFT JOIN brands b ON mp.brand_id = b.id
      WHERE bp.id = $1
    `;

    const detailResult = await database.query(detailQuery, [id]);
    const businessProduct = formatBusinessProduct(detailResult.rows[0]);

    res.json({
      success: true,
      message: 'Business product updated successfully',
      data: businessProduct
    });

  } catch (error) {
    console.error('Error updating business product:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error updating business product', 
      error: error.message 
    });
  }
});

// DELETE /api/business-products/:id - Remove a product from business
router.delete('/:id', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.uid;
    const userRole = req.user.role;
    const { id } = req.params;

    // Check if business product exists and user has permission
    let checkQuery = 'SELECT * FROM business_products WHERE id = $1';
    let checkParams = [id];

    if (userRole !== 'super_admin') {
      checkQuery += ' AND business_id = $2';
      checkParams.push(userId);
    }

    const existing = await database.query(checkQuery, checkParams);
    
    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business product not found or you do not have permission to delete it'
      });
    }

    // Check if there are active price listings for this business product
    const priceListingCheck = await database.query(
      'SELECT COUNT(*) as count FROM price_listings WHERE business_id = $1 AND master_product_id = $2 AND is_active = true',
      [existing.rows[0].business_id, existing.rows[0].master_product_id]
    );

    if (parseInt(priceListingCheck.rows[0].count) > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot remove product with active price listings. Please deactivate price listings first.'
      });
    }

    // Soft delete by setting is_active to false
    const deleteQuery = `
      UPDATE business_products 
      SET is_active = false, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;

    const result = await database.query(deleteQuery, [id]);

    res.json({
      success: true,
      message: 'Product removed from business successfully',
      data: formatBusinessProduct(result.rows[0])
    });

  } catch (error) {
    console.error('Error removing business product:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error removing business product', 
      error: error.message 
    });
  }
});

// POST /api/business-products/bulk-add - Add multiple products to business
router.post('/bulk-add', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.uid;
    
    // Verify user is a verified business
    const businessCheck = await database.query(
      'SELECT id FROM new_business_verifications WHERE user_id = $1 AND status = $2',
      [userId, 'approved']
    );

    if (businessCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Only verified businesses can add products'
      });
    }

    const { productIds, countryCode = 'LK' } = req.body;

    if (!productIds || !Array.isArray(productIds) || productIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Product IDs array is required'
      });
    }

    const results = [];
    const errors = [];

    for (const productId of productIds) {
      try {
        // Check if product exists
        const productCheck = await database.query(
          'SELECT id FROM master_products WHERE id = $1 AND is_active = true',
          [productId]
        );

        if (productCheck.rows.length === 0) {
          errors.push({ productId, error: 'Product not found or inactive' });
          continue;
        }

        // Check if already exists
        const existingCheck = await database.query(
          'SELECT id FROM business_products WHERE business_id = $1 AND master_product_id = $2 AND country_code = $3',
          [userId, productId, countryCode]
        );

        if (existingCheck.rows.length > 0) {
          errors.push({ productId, error: 'Product already added' });
          continue;
        }

        // Add the product
        const insertResult = await database.query(
          `INSERT INTO business_products (business_id, master_product_id, country_code, is_active)
           VALUES ($1, $2, $3, true) RETURNING id`,
          [userId, productId, countryCode]
        );

        results.push({ productId, businessProductId: insertResult.rows[0].id });

      } catch (error) {
        errors.push({ productId, error: error.message });
      }
    }

    res.json({
      success: true,
      message: `Added ${results.length} products successfully`,
      data: {
        added: results,
        errors: errors,
        summary: {
          total: productIds.length,
          successful: results.length,
          failed: errors.length
        }
      }
    });

  } catch (error) {
    console.error('Error bulk adding business products:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error bulk adding business products', 
      error: error.message 
    });
  }
});

module.exports = router;
