const express = require('express');
const router = express.Router();
const database = require('../services/database');

// Get business registration form data
router.get('/form-data', async (req, res) => {
  try {
    const { country_code = 'LK' } = req.query;

    // Get business types for the country
    const businessTypesQuery = `
      SELECT id, name, description, icon, display_order
      FROM business_types 
      WHERE country_code = $1 AND is_active = true
      ORDER BY display_order, name
    `;

    // Get categories that businesses can operate in
    const categoriesQuery = `
      SELECT id, name, slug, type, is_active
      FROM categories 
      WHERE is_active = true
      ORDER BY name
    `;

    // Get subcategories grouped by category
    const subcategoriesQuery = `
      SELECT sc.id, sc.name, sc.slug, sc.category_id,
             c.name as category_name
      FROM sub_categories sc
      JOIN categories c ON sc.category_id = c.id
      WHERE sc.is_active = true AND c.is_active = true
      ORDER BY c.name, sc.name
    `;

    const [businessTypes, categories, subcategories] = await Promise.all([
      database.query(businessTypesQuery, [country_code]),
      database.query(categoriesQuery, []),
      database.query(subcategoriesQuery, [])
    ]);

    // Group subcategories by category
    const categoriesWithSubs = categories.rows.map(category => ({
      ...category,
      subcategories: subcategories.rows.filter(sub => sub.category_id === category.id)
    }));

    res.json({
      success: true,
      data: {
        businessTypes: businessTypes.rows,
        categories: categoriesWithSubs,
        flatCategories: categories.rows, // For simple category selection
        flatSubcategories: subcategories.rows // For simple subcategory selection
      }
    });
  } catch (error) {
    console.error('Error fetching business registration form data:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching form data',
      error: error.message
    });
  }
});

// Get categories hierarchy for multi-select
router.get('/categories-hierarchy', async (req, res) => {
  try {
    const { country_code = 'LK' } = req.query;

    const query = `
      SELECT 
        c.id as category_id,
        c.name as category_name,
        c.type as category_type,
        sc.id as subcategory_id,
        sc.name as subcategory_name
      FROM categories c
      LEFT JOIN sub_categories sc ON c.id = sc.category_id AND sc.is_active = true
      WHERE c.is_active = true
      ORDER BY c.name, sc.name
    `;

    const result = await database.query(query, []);

    // Build hierarchy
    const hierarchy = {};
    
    result.rows.forEach(row => {
      if (!hierarchy[row.category_id]) {
        hierarchy[row.category_id] = {
          id: row.category_id,
          name: row.category_name,
          type: row.category_type,
          subcategories: []
        };
      }

      if (row.subcategory_id) {
        hierarchy[row.category_id].subcategories.push({
          id: row.subcategory_id,
          name: row.subcategory_name
        });
      }
    });

    const categoriesArray = Object.values(hierarchy).sort((a, b) => a.name.localeCompare(b.name));

    res.json({
      success: true,
      data: categoriesArray
    });
  } catch (error) {
    console.error('Error fetching categories hierarchy:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching categories',
      error: error.message
    });
  }
});

// Get business type details by ID
router.get('/business-type/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      SELECT id, name, description, icon, country_code
      FROM business_types 
      WHERE id = $1 AND is_active = true
    `;

    const result = await database.queryOne(query, [id]);

    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Business type not found'
      });
    }

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    console.error('Error fetching business type:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching business type',
      error: error.message
    });
  }
});

module.exports = router;
