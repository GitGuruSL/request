const express = require('express');
const dbService = require('../services/database');
const authService = require('../services/auth');

const router = express.Router();

/**
 * @route GET /api/categories
 * @desc Get categories - Super Admin sees all, Country Admin sees country-specific
 */
router.get('/', async (req, res) => {
    try {
        const { includeInactive = false, country = 'LK', type } = req.query;
        const user = req.user || { role: 'super_admin' }; // Default to super_admin for testing

        let categories;
        
        if (user.role === 'super_admin') {
            // Super Admin: Get all global categories
            let conditions = {};
            if (!includeInactive) {
                conditions.is_active = true;
            }
            
            // Filter by type if specified
            if (type) {
                conditions.type = type;
            }

            categories = await dbService.findMany('categories', conditions, {
                orderBy: 'name',
                orderDirection: 'ASC'
            });
        } else {
            // Country Admin: Get categories enabled for their country
            const countryCode = user.country_code || country; // Use country from query if not in user profile
            
            let query = `
                SELECT c.*, cc.is_active as country_active, cc.display_order
                FROM categories c
                INNER JOIN country_categories cc ON c.id = cc.category_id
                WHERE cc.country_code = $1
                ${!includeInactive ? 'AND c.is_active = true AND cc.is_active = true' : ''}
            `;
            
            const params = [countryCode];
            
            // Add type filter if specified
            if (type) {
                query += ` AND c.type = $${params.length + 1}`;
                params.push(type);
            }
            
            query += ` ORDER BY cc.display_order ASC, c.name ASC`;
            
            const result = await dbService.query(query, params);
            categories = result.rows;
        }

        res.json({
            success: true,
            data: categories,
            count: categories.length,
            isGlobalView: user.role === 'super_admin',
            filteredByType: type || null
        });
    } catch (error) {
        console.error('Get categories error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route GET /api/categories/:id
 * @desc Get category by ID
 */
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const category = await dbService.findById('categories', id);
        
        if (!category) {
            return res.status(404).json({
                success: false,
                error: 'Category not found'
            });
        }

        res.json({
            success: true,
            data: category
        });
    } catch (error) {
        console.error('Get category error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route GET /api/categories/:id/subcategories
 * @desc Get subcategories for a category
 */
router.get('/:id/subcategories', async (req, res) => {
    try {
        const { id } = req.params;
        const { includeInactive = false } = req.query;

        let conditions = { category_id: id };
        if (!includeInactive) {
            conditions.is_active = true;
        }

        const subcategories = await dbService.findMany('sub_categories', conditions, {
            orderBy: 'name',
            orderDirection: 'ASC'
        });

        res.json({
            success: true,
            data: subcategories,
            count: subcategories.length
        });
    } catch (error) {
        console.error('Get subcategories error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route POST /api/categories
 * @desc Create new category (Admin only)
 */
router.post('/', 
    authService.authMiddleware(), 
    authService.roleMiddleware(['admin','super_admin']), 
    async (req, res) => {
        try {
            const { name, description, icon, displayOrder, countryCode = 'LK' } = req.body;

            if (!name) {
                return res.status(400).json({
                    error: 'Category name is required'
                });
            }

            const category = await dbService.insert('categories', {
                name,
                description,
                icon,
                display_order: displayOrder || 0,
                country_code: countryCode,
                is_active: true,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            });

            res.status(201).json({
                success: true,
                message: 'Category created successfully',
                data: category
            });
        } catch (error) {
            console.error('Create category error:', error);
            res.status(400).json({
                success: false,
                error: error.message
            });
        }
    }
);

/**
 * @route PUT /api/categories/:id
 * @desc Update category (Admin only)
 */
router.put('/:id', 
    authService.authMiddleware(), 
    authService.roleMiddleware(['admin','super_admin']), 
    async (req, res) => {
        try {
            const { id } = req.params;
            const { name, description, icon, displayOrder, isActive } = req.body;

            const updateData = {};
            if (name !== undefined) updateData.name = name;
            if (description !== undefined) updateData.description = description;
            if (icon !== undefined) updateData.icon = icon;
            if (displayOrder !== undefined) updateData.display_order = displayOrder;
            if (isActive !== undefined) updateData.is_active = isActive;

            if (Object.keys(updateData).length === 0) {
                return res.status(400).json({
                    error: 'No valid fields to update'
                });
            }

            const category = await dbService.update('categories', id, updateData);

            if (!category) {
                return res.status(404).json({
                    success: false,
                    error: 'Category not found'
                });
            }

            res.json({
                success: true,
                message: 'Category updated successfully',
                data: category
            });
        } catch (error) {
            console.error('Update category error:', error);
            res.status(400).json({
                success: false,
                error: error.message
            });
        }
    }
);

/**
 * @route DELETE /api/categories/:id
 * @desc Delete category (Admin only)
 */
router.delete('/:id', 
    authService.authMiddleware(), 
    authService.roleMiddleware(['admin','super_admin']), 
    async (req, res) => {
        try {
            const { id } = req.params;

            // Check if category has subcategories
            const subcategoriesCount = await dbService.count('subcategories', { category_id: id });
            if (subcategoriesCount > 0) {
                return res.status(400).json({
                    success: false,
                    error: 'Cannot delete category with existing subcategories'
                });
            }

            const category = await dbService.delete('categories', id);

            if (!category) {
                return res.status(404).json({
                    success: false,
                    error: 'Category not found'
                });
            }

            res.json({
                success: true,
                message: 'Category deleted successfully'
            });
        } catch (error) {
            console.error('Delete category error:', error);
            res.status(400).json({
                success: false,
                error: error.message
            });
        }
    }
);

/**
 * @route POST /api/categories/:id/country-toggle
 * @desc Toggle category for country (Country Admin only)
 */
router.post('/:id/country-toggle', 
    authService.authMiddleware(), 
    authService.roleMiddleware(['admin', 'country_admin']), 
    async (req, res) => {
        try {
            const { id: categoryId } = req.params;
            const { isActive, displayOrder } = req.body;
            const user = req.user;
            
            // Country admins can only manage their own country
            const countryCode = user.role === 'super_admin' ? req.body.countryCode : user.country_code;
            
            if (!countryCode) {
                return res.status(400).json({
                    success: false,
                    error: 'Country code is required'
                });
            }

            // Check if category exists
            const category = await dbService.findById('categories', categoryId);
            if (!category) {
                return res.status(404).json({
                    success: false,
                    error: 'Category not found'
                });
            }

            // Upsert country_categories
            const query = `
                INSERT INTO country_categories (category_id, country_code, is_active, display_order, created_at, updated_at)
                VALUES ($1, $2, $3, $4, NOW(), NOW())
                ON CONFLICT (category_id, country_code)
                DO UPDATE SET
                    is_active = EXCLUDED.is_active,
                    display_order = EXCLUDED.display_order,
                    updated_at = NOW()
                RETURNING *
            `;
            
            const result = await dbService.query(query, [
                categoryId, 
                countryCode, 
                isActive !== undefined ? isActive : true,
                displayOrder || 0
            ]);

            res.json({
                success: true,
                data: result.rows[0],
                message: `Category ${isActive ? 'enabled' : 'disabled'} for ${countryCode}`
            });
        } catch (error) {
            console.error('Toggle category for country error:', error);
            res.status(400).json({
                success: false,
                error: error.message
            });
        }
    }
);

/**
 * @route GET /api/categories/country/:countryCode
 * @desc Get all categories with country-specific status (Super Admin only)
 */
router.get('/country/:countryCode', 
    authService.authMiddleware(), 
    authService.roleMiddleware(['super_admin']), 
    async (req, res) => {
        try {
            const { countryCode } = req.params;
            
            const query = `
                SELECT 
                    c.*,
                    cc.is_active as country_active,
                    cc.display_order,
                    CASE WHEN cc.category_id IS NOT NULL THEN true ELSE false END as is_enabled_in_country
                FROM categories c
                LEFT JOIN country_categories cc ON c.id = cc.category_id AND cc.country_code = $1
                WHERE c.is_active = true
                ORDER BY cc.display_order ASC NULLS LAST, c.name ASC
            `;
            
            const result = await dbService.query(query, [countryCode]);

            res.json({
                success: true,
                data: result.rows,
                count: result.rows.length,
                countryCode
            });
        } catch (error) {
            console.error('Get categories for country error:', error);
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    }
);

module.exports = router;
