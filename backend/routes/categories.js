const express = require('express');
const dbService = require('../services/database');
const authService = require('../services/auth');

const router = express.Router();

/**
 * @route GET /api/categories
 * @desc Get all active categories for a country
 */
router.get('/', async (req, res) => {
    try {
        const { country = 'LK', includeInactive = false } = req.query;

        let conditions = { country_code: country };
        if (!includeInactive) {
            conditions.is_active = true;
        }

        const categories = await dbService.findMany('categories', conditions, {
            orderBy: 'display_order, name',
            orderDirection: 'ASC'
        });

        res.json({
            success: true,
            data: categories,
            count: categories.length
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

        const subcategories = await dbService.findMany('subcategories', conditions, {
            orderBy: 'display_order, name',
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

module.exports = router;
