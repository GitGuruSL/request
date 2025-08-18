const express = require('express');
const router = express.Router();
const dbService = require('../services/database');

// Get all subcategories
router.get('/', async (req, res) => {
    try {
        console.log('Fetching subcategories...');
        
        // Get subcategories with category information
        const result = await dbService.query(`
            SELECT 
                sc.*,
                c.name as category_name
            FROM sub_categories sc
            LEFT JOIN categories c ON sc.category_id = c.id
            WHERE sc.is_active = true
            ORDER BY c.name, sc.name
        `);

        console.log(`Found ${result.rows.length} subcategories`);
        
        res.json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        console.error('Error fetching subcategories:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch subcategories'
        });
    }
});

// Get subcategories by category ID
router.get('/category/:categoryId', async (req, res) => {
    try {
        const { categoryId } = req.params;
        
        const result = await dbService.query(`
            SELECT * FROM sub_categories 
            WHERE category_id = $1 AND is_active = true
            ORDER BY name
        `, [categoryId]);

        res.json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        console.error('Error fetching subcategories by category:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch subcategories'
        });
    }
});

// Create new subcategory (Super Admin only)
router.post('/', async (req, res) => {
    try {
        const { category_id, name, slug, metadata } = req.body;
        const user = req.user || { role: 'super_admin' }; // Default for testing
        
        // Check if user is super admin
        if (user.role !== 'super_admin') {
            return res.status(403).json({
                success: false,
                error: 'Only super admins can create subcategories'
            });
        }

        const result = await dbService.query(`
            INSERT INTO sub_categories (category_id, name, slug, metadata, is_active, created_at, updated_at)
            VALUES ($1, $2, $3, $4, true, NOW(), NOW())
            RETURNING *
        `, [category_id, name, slug || name.toLowerCase().replace(/\s+/g, '-'), metadata || {}]);

        res.status(201).json({
            success: true,
            data: result.rows[0],
            message: 'Subcategory created successfully'
        });
    } catch (error) {
        console.error('Error creating subcategory:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create subcategory'
        });
    }
});

// Update subcategory (Super Admin only)
router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { category_id, name, slug, metadata, is_active } = req.body;
        const user = req.user || { role: 'super_admin' }; // Default for testing
        
        // Check if user is super admin
        if (user.role !== 'super_admin') {
            return res.status(403).json({
                success: false,
                error: 'Only super admins can update subcategories'
            });
        }

        const result = await dbService.query(`
            UPDATE sub_categories 
            SET category_id = $2, name = $3, slug = $4, metadata = $5, is_active = $6, updated_at = NOW()
            WHERE id = $1
            RETURNING *
        `, [id, category_id, name, slug, metadata, is_active]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Subcategory not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0],
            message: 'Subcategory updated successfully'
        });
    } catch (error) {
        console.error('Error updating subcategory:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update subcategory'
        });
    }
});

// Delete subcategory (Super Admin only)
router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const user = req.user || { role: 'super_admin' }; // Default for testing
        
        // Check if user is super admin
        if (user.role !== 'super_admin') {
            return res.status(403).json({
                success: false,
                error: 'Only super admins can delete subcategories'
            });
        }

        // Soft delete by setting is_active to false
        const result = await dbService.query(`
            UPDATE sub_categories 
            SET is_active = false, updated_at = NOW()
            WHERE id = $1
            RETURNING *
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Subcategory not found'
            });
        }

        res.json({
            success: true,
            message: 'Subcategory deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting subcategory:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete subcategory'
        });
    }
});

module.exports = router;
