const express = require('express');
const database = require('../services/database');
const auth = require('../services/auth');
const multer = require('multer');
const path = require('path');

const router = express.Router();

// Multer configuration for image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/price-listings/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'listing-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image files (JPEG, PNG, WebP) are allowed'));
    }
  }
});

// Helper function to format price listing data
function formatPriceListing(row, includeBusiness = false) {
  if (!row) return null;
  
  const listing = {
    id: row.id,
    businessId: row.business_id,
    masterProductId: row.master_product_id,
    title: row.title,
    description: row.description,
    price: parseFloat(row.price) || 0,
    currency: row.currency || 'LKR',
    unit: row.unit,
    deliveryCharge: parseFloat(row.delivery_charge) || 0,
    images: row.images ? (Array.isArray(row.images) ? row.images : JSON.parse(row.images || '[]')) : [],
    website: row.website,
    whatsapp: row.whatsapp,
    cityId: row.city_id,
    countryCode: row.country_code,
    isActive: row.is_active,
    viewCount: row.view_count || 0,
    contactCount: row.contact_count || 0,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
  
  // Add business details if included in query
  if (includeBusiness && row.business_name) {
    listing.business = {
      name: row.business_name,
      category: row.business_category,
      isVerified: row.business_verified || false
    };
  }
  
  // Add product details if included
  if (row.product_name) {
    listing.product = {
      name: row.product_name,
      brandId: row.brand_id,
      brandName: row.brand_name,
      baseUnit: row.base_unit
    };
  }
  
  return listing;
}

// GET /api/price-listings - Get all price listings with optional filters
router.get('/', async (req, res) => {
  try {
    const { 
      masterProductId, 
      businessId, 
      categoryId, 
      subcategoryId,
      cityId,
      country = 'LK',
      minPrice,
      maxPrice,
      search,
      sortBy = 'price', // price, rating, created_at
      sortOrder = 'asc',
      page = 1,
      limit = 20,
      includeInactive = 'false'
    } = req.query;

    let whereConditions = [];
    let queryParams = [];
    let paramIndex = 1;

    // Base query with business and product details
    let query = `
      SELECT 
        pl.*,
        mp.name as product_name,
        mp.base_unit,
        b.name as brand_name,
        bv.business_name,
        bv.business_category,
        bv.is_verified as business_verified,
        c.name as city_name
      FROM price_listings pl
      LEFT JOIN master_products mp ON pl.master_product_id = mp.id
      LEFT JOIN brands b ON mp.brand_id = b.id
      LEFT JOIN business_verifications bv ON pl.business_id = bv.user_id
      LEFT JOIN cities c ON pl.city_id = c.id
    `;

    // Apply filters
    if (country) {
      whereConditions.push(`pl.country_code = $${paramIndex}`);
      queryParams.push(country);
      paramIndex++;
    }

    if (includeInactive !== 'true') {
      whereConditions.push(`pl.is_active = true`);
    }

    if (masterProductId) {
      whereConditions.push(`pl.master_product_id = $${paramIndex}`);
      queryParams.push(masterProductId);
      paramIndex++;
    }

    if (businessId) {
      whereConditions.push(`pl.business_id = $${paramIndex}`);
      queryParams.push(businessId);
      paramIndex++;
    }

    if (categoryId) {
      whereConditions.push(`pl.category_id = $${paramIndex}`);
      queryParams.push(categoryId);
      paramIndex++;
    }

    if (subcategoryId) {
      whereConditions.push(`pl.subcategory_id = $${paramIndex}`);
      queryParams.push(subcategoryId);
      paramIndex++;
    }

    if (cityId) {
      whereConditions.push(`pl.city_id = $${paramIndex}`);
      queryParams.push(cityId);
      paramIndex++;
    }

    if (minPrice) {
      whereConditions.push(`pl.price >= $${paramIndex}`);
      queryParams.push(parseFloat(minPrice));
      paramIndex++;
    }

    if (maxPrice) {
      whereConditions.push(`pl.price <= $${paramIndex}`);
      queryParams.push(parseFloat(maxPrice));
      paramIndex++;
    }

    if (search) {
      whereConditions.push(`(pl.title ILIKE $${paramIndex} OR pl.description ILIKE $${paramIndex} OR mp.name ILIKE $${paramIndex})`);
      queryParams.push(`%${search}%`);
      paramIndex++;
    }

    // Add WHERE clause if we have conditions
    if (whereConditions.length > 0) {
      query += ` WHERE ${whereConditions.join(' AND ')}`;
    }

    // Add sorting
    let orderBy = '';
    switch (sortBy) {
      case 'price':
        orderBy = `pl.price ${sortOrder.toUpperCase()}`;
        break;
      case 'rating':
        orderBy = `bv.business_name ${sortOrder.toUpperCase()}`; // Sort by business name instead of rating
        break;
      case 'created_at':
        orderBy = `pl.created_at ${sortOrder.toUpperCase()}`;
        break;
      default:
        orderBy = `pl.price ASC`;
    }
    query += ` ORDER BY ${orderBy}`;

    // Add pagination
    const offset = (page - 1) * limit;
    query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    queryParams.push(limit, offset);

    console.log('Price listings query:', query);
    console.log('Params:', queryParams);

    const result = await database.query(query, queryParams);
    const listings = result.rows.map(row => formatPriceListing(row, true));

    // Get total count for pagination
    let countQuery = `
      SELECT COUNT(*) as total
      FROM price_listings pl
      LEFT JOIN master_products mp ON pl.master_product_id = mp.id
      LEFT JOIN business_verifications bv ON pl.business_id = bv.user_id
    `;
    
    if (whereConditions.length > 0) {
      countQuery += ` WHERE ${whereConditions.join(' AND ')}`;
    }

    const countResult = await database.query(countQuery, queryParams.slice(0, -2)); // Remove limit and offset
    const total = parseInt(countResult.rows[0].total);

    res.json({
      success: true,
      data: listings,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Error fetching price listings:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error fetching price listings', 
      error: error.message 
    });
  }
});

// GET /api/price-listings/search - Search products for price comparison
router.get('/search', async (req, res) => {
  try {
    const { 
      q: query, 
      country = 'LK', 
      categoryId, 
      brandId,
      limit = 10
    } = req.query;

    if (!query || query.trim().length < 2) {
      return res.json({
        success: true,
        data: [],
        message: 'Query too short'
      });
    }

    let searchQuery = `
      SELECT DISTINCT
        mp.id,
        mp.name,
        mp.slug,
        mp.base_unit,
        b.name as brand_name,
        b.id as brand_id,
        COUNT(pl.id) as listing_count,
        MIN(pl.price) as min_price,
        MAX(pl.price) as max_price,
        AVG(pl.price) as avg_price
      FROM master_products mp
      LEFT JOIN brands b ON mp.brand_id = b.id
      LEFT JOIN price_listings pl ON mp.id = pl.master_product_id 
        AND pl.is_active = true 
        AND pl.country_code = $1
      WHERE mp.is_active = true
        AND mp.name ILIKE $2
    `;

    let queryParams = [country, `%${query.trim()}%`];
    let paramIndex = 3;

    if (categoryId) {
      searchQuery += ` AND EXISTS (
        SELECT 1 FROM price_listings pl2 
        WHERE pl2.master_product_id = mp.id 
        AND pl2.category_id = $${paramIndex}
      )`;
      queryParams.push(categoryId);
      paramIndex++;
    }

    if (brandId) {
      searchQuery += ` AND mp.brand_id = $${paramIndex}`;
      queryParams.push(brandId);
      paramIndex++;
    }

    searchQuery += `
      GROUP BY mp.id, mp.name, mp.slug, mp.base_unit, b.name, b.id
      ORDER BY listing_count DESC, mp.name
      LIMIT $${paramIndex}
    `;
    queryParams.push(limit);

    console.log('Product search query:', searchQuery);
    console.log('Params:', queryParams);

    const result = await database.query(searchQuery, queryParams);
    
    const products = result.rows.map(row => ({
      id: row.id,
      name: row.name,
      slug: row.slug,
      baseUnit: row.base_unit,
      brand: row.brand_name ? {
        id: row.brand_id,
        name: row.brand_name
      } : null,
      listingCount: parseInt(row.listing_count) || 0,
      priceRange: {
        min: parseFloat(row.min_price) || 0,
        max: parseFloat(row.max_price) || 0,
        avg: parseFloat(row.avg_price) || 0
      }
    }));

    res.json({
      success: true,
      data: products,
      count: products.length
    });

  } catch (error) {
    console.error('Error searching products:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error searching products', 
      error: error.message 
    });
  }
});

// GET /api/price-listings/product/:productId - Get price listings for a specific product
router.get('/product/:productId', async (req, res) => {
  try {
    const { productId } = req.params;
    const { country = 'LK', sortBy = 'price' } = req.query;

    // Get product details first
    const productQuery = `
      SELECT mp.*, b.name as brand_name
      FROM master_products mp
      LEFT JOIN brands b ON mp.brand_id = b.id
      WHERE mp.id = $1 AND mp.is_active = true
    `;
    
    const productResult = await database.query(productQuery, [productId]);
    
    if (productResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    const product = productResult.rows[0];

    // Get price listings for this product
    let orderBy = 'pl.price ASC'; // Default: cheapest first
    if (sortBy === 'rating') {
      orderBy = 'bv.business_name ASC, pl.price ASC'; // Sort by business name instead of rating
    } else if (sortBy === 'newest') {
      orderBy = 'pl.created_at DESC';
    }

    const listingsQuery = `
      SELECT 
        pl.*,
        bv.business_name,
        bv.business_category,
        bv.is_verified as business_verified,
        c.name as city_name
      FROM price_listings pl
      LEFT JOIN business_verifications bv ON pl.business_id = bv.user_id
      LEFT JOIN cities c ON pl.city_id = c.id
      WHERE pl.master_product_id = $1 
        AND pl.country_code = $2 
        AND pl.is_active = true
      ORDER BY ${orderBy}
    `;

    const listingsResult = await database.query(listingsQuery, [productId, country]);
    const listings = listingsResult.rows.map(row => formatPriceListing(row, true));

    res.json({
      success: true,
      data: {
        product: {
          id: product.id,
          name: product.name,
          slug: product.slug,
          baseUnit: product.base_unit,
          brand: product.brand_name ? { name: product.brand_name } : null
        },
        listings,
        summary: {
          totalListings: listings.length,
          priceRange: listings.length > 0 ? {
            min: Math.min(...listings.map(l => l.price)),
            max: Math.max(...listings.map(l => l.price)),
            avg: listings.reduce((sum, l) => sum + l.price, 0) / listings.length
          } : { min: 0, max: 0, avg: 0 }
        }
      }
    });

  } catch (error) {
    console.error('Error fetching product price listings:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error fetching product price listings', 
      error: error.message 
    });
  }
});

// GET /api/price-listings/:id - Get a specific price listing
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      SELECT 
        pl.*,
        mp.name as product_name,
        mp.base_unit,
        b.name as brand_name,
        bv.business_name,
        bv.business_category,
        bv.is_verified as business_verified,
        c.name as city_name
      FROM price_listings pl
      LEFT JOIN master_products mp ON pl.master_product_id = mp.id
      LEFT JOIN brands b ON mp.brand_id = b.id
      LEFT JOIN business_verifications bv ON pl.business_id = bv.user_id
      LEFT JOIN cities c ON pl.city_id = c.id
      WHERE pl.id = $1
    `;

    const result = await database.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Price listing not found'
      });
    }

    const listing = formatPriceListing(result.rows[0], true);

    res.json({
      success: true,
      data: listing
    });

  } catch (error) {
    console.error('Error fetching price listing:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error fetching price listing', 
      error: error.message 
    });
  }
});

// POST /api/price-listings - Create a new price listing (Business users only)
router.post('/', auth.authMiddleware(), upload.array('images', 5), async (req, res) => {
  try {
    const userId = req.user.uid;
    
    // Verify user is a verified business
    const businessCheck = await database.query(
      'SELECT id, business_name, is_verified FROM business_verifications WHERE user_id = $1 AND status = $2',
      [userId, 'approved']
    );

    if (businessCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Only verified businesses can create price listings'
      });
    }

    const {
      masterProductId,
      categoryId,
      subcategoryId,
      title,
      description,
      price,
      currency = 'LKR',
      unit,
      deliveryCharge = 0,
      website,
      whatsapp,
      cityId,
      countryCode = 'LK'
    } = req.body;

    // Validate required fields
    if (!masterProductId || !title || !price) {
      return res.status(400).json({
        success: false,
        message: 'Master product ID, title, and price are required'
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

    // Handle uploaded images
    const images = req.files ? req.files.map(file => `/uploads/price-listings/${file.filename}`) : [];

    // Create the price listing (allow multiple listings per business for same product)
    const insertQuery = `
      INSERT INTO price_listings (
        business_id, master_product_id, category_id, subcategory_id,
        title, description, price, currency, unit, delivery_charge,
        images, website, whatsapp, city_id, country_code
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING *
    `;

    const values = [
      userId, masterProductId, categoryId, subcategoryId,
      title, description, parseFloat(price), currency, unit, parseFloat(deliveryCharge),
      JSON.stringify(images), website, whatsapp, cityId, countryCode
    ];

    const result = await database.query(insertQuery, values);
    const newListing = formatPriceListing(result.rows[0]);

    res.status(201).json({
      success: true,
      message: 'Price listing created successfully',
      data: newListing
    });

  } catch (error) {
    console.error('Error creating price listing:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error creating price listing', 
      error: error.message 
    });
  }
});

// PUT /api/price-listings/:id - Update a price listing (Business owner only)
router.put('/:id', auth.authMiddleware(), upload.array('images', 5), async (req, res) => {
  try {
    const userId = req.user.uid;
    const { id } = req.params;

    // Check if listing exists and belongs to the user
    const existingListing = await database.query(
      'SELECT * FROM price_listings WHERE id = $1 AND business_id = $2',
      [id, userId]
    );

    if (existingListing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Price listing not found or you do not have permission to edit it'
      });
    }

    const {
      title,
      description,
      price,
      currency,
      unit,
      deliveryCharge,
      website,
      whatsapp,
      cityId,
      isActive
    } = req.body;

    // Handle uploaded images
    let images = existingListing.rows[0].images || [];
    if (typeof images === 'string') {
      images = JSON.parse(images);
    }
    
    if (req.files && req.files.length > 0) {
      const newImages = req.files.map(file => `/uploads/price-listings/${file.filename}`);
      images = [...images, ...newImages];
    }

    // Build update query dynamically
    const updateFields = [];
    const updateValues = [];
    let paramIndex = 1;

    if (title !== undefined) {
      updateFields.push(`title = $${paramIndex}`);
      updateValues.push(title);
      paramIndex++;
    }

    if (description !== undefined) {
      updateFields.push(`description = $${paramIndex}`);
      updateValues.push(description);
      paramIndex++;
    }

    if (price !== undefined) {
      updateFields.push(`price = $${paramIndex}`);
      updateValues.push(parseFloat(price));
      paramIndex++;
    }

    if (currency !== undefined) {
      updateFields.push(`currency = $${paramIndex}`);
      updateValues.push(currency);
      paramIndex++;
    }

    if (unit !== undefined) {
      updateFields.push(`unit = $${paramIndex}`);
      updateValues.push(unit);
      paramIndex++;
    }

    if (deliveryCharge !== undefined) {
      updateFields.push(`delivery_charge = $${paramIndex}`);
      updateValues.push(parseFloat(deliveryCharge));
      paramIndex++;
    }

    if (website !== undefined) {
      updateFields.push(`website = $${paramIndex}`);
      updateValues.push(website);
      paramIndex++;
    }

    if (whatsapp !== undefined) {
      updateFields.push(`whatsapp = $${paramIndex}`);
      updateValues.push(whatsapp);
      paramIndex++;
    }

    if (cityId !== undefined) {
      updateFields.push(`city_id = $${paramIndex}`);
      updateValues.push(cityId);
      paramIndex++;
    }

    if (isActive !== undefined) {
      updateFields.push(`is_active = $${paramIndex}`);
      updateValues.push(isActive);
      paramIndex++;
    }

    if (images !== existingListing.rows[0].images) {
      updateFields.push(`images = $${paramIndex}`);
      updateValues.push(JSON.stringify(images));
      paramIndex++;
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update'
      });
    }

    // Add updated_at
    updateFields.push(`updated_at = NOW()`);

    const updateQuery = `
      UPDATE price_listings 
      SET ${updateFields.join(', ')}
      WHERE id = $${paramIndex} AND business_id = $${paramIndex + 1}
      RETURNING *
    `;
    
    updateValues.push(id, userId);

    const result = await database.query(updateQuery, updateValues);
    const updatedListing = formatPriceListing(result.rows[0]);

    res.json({
      success: true,
      message: 'Price listing updated successfully',
      data: updatedListing
    });

  } catch (error) {
    console.error('Error updating price listing:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error updating price listing', 
      error: error.message 
    });
  }
});

// DELETE /api/price-listings/:id - Delete/deactivate a price listing (Business owner only)
router.delete('/:id', auth.authMiddleware(), async (req, res) => {
  try {
    const userId = req.user.uid;
    const { id } = req.params;

    // Check if listing exists and belongs to the user
    const existingListing = await database.query(
      'SELECT * FROM price_listings WHERE id = $1 AND business_id = $2',
      [id, userId]
    );

    if (existingListing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Price listing not found or you do not have permission to delete it'
      });
    }

    // Soft delete by setting is_active to false
    const deleteQuery = `
      UPDATE price_listings 
      SET is_active = false, updated_at = NOW()
      WHERE id = $1 AND business_id = $2
      RETURNING *
    `;

    const result = await database.query(deleteQuery, [id, userId]);

    res.json({
      success: true,
      message: 'Price listing deleted successfully',
      data: formatPriceListing(result.rows[0])
    });

  } catch (error) {
    console.error('Error deleting price listing:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error deleting price listing', 
      error: error.message 
    });
  }
});

// POST /api/price-listings/:id/track-view - Track when someone views a listing
router.post('/:id/track-view', async (req, res) => {
  try {
    const { id } = req.params;

    const updateQuery = `
      UPDATE price_listings 
      SET view_count = view_count + 1
      WHERE id = $1 AND is_active = true
      RETURNING view_count
    `;

    const result = await database.query(updateQuery, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Price listing not found'
      });
    }

    res.json({
      success: true,
      data: { viewCount: result.rows[0].view_count }
    });

  } catch (error) {
    console.error('Error tracking view:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error tracking view', 
      error: error.message 
    });
  }
});

// POST /api/price-listings/:id/track-contact - Track when someone contacts a business
router.post('/:id/track-contact', async (req, res) => {
  try {
    const { id } = req.params;

    const updateQuery = `
      UPDATE price_listings 
      SET contact_count = contact_count + 1
      WHERE id = $1 AND is_active = true
      RETURNING contact_count
    `;

    const result = await database.query(updateQuery, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Price listing not found'
      });
    }

    res.json({
      success: true,
      data: { contactCount: result.rows[0].contact_count }
    });

  } catch (error) {
    console.error('Error tracking contact:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error tracking contact', 
      error: error.message 
    });
  }
});

module.exports = router;
