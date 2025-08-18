const express = require('express');
const router = express.Router();
const dbService = require('../services/database');
const authService = require('../services/auth');

// Get all country subcategories
router.get('/', async (req, res) => {
    try {
        console.log('Fetching country subcategories...');
        
        const result = await dbService.query(`
            SELECT 
                cs.*,
                sc.name as subcategory_name,
                c.name as category_name,
                co.name as country_name
            FROM country_subcategories cs
            LEFT JOIN sub_categories sc ON cs.subcategory_id = sc.id
            LEFT JOIN categories c ON sc.category_id = c.id
            LEFT JOIN countries co ON cs.country_code = co.code
            ORDER BY co.name, c.name, sc.name
        `);

        console.log(`Found ${result.rows.length} country subcategories`);
        
        res.json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        console.error('Error fetching country subcategories:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch country subcategories'
        });
    }
});

// Get country subcategory by ID
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await dbService.query(`
            SELECT 
                cs.*,
                sc.name as subcategory_name,
                c.name as category_name,
                co.name as country_name
            FROM country_subcategories cs
            LEFT JOIN sub_categories sc ON cs.subcategory_id = sc.id
            LEFT JOIN categories c ON sc.category_id = c.id
            LEFT JOIN countries co ON cs.country_code = co.code
            WHERE cs.id = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Country subcategory not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error fetching country subcategory:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch country subcategory'
        });
    }
});

// Create new country subcategory
router.post('/', authService.authMiddleware(), async (req, res) => {
    try {
        const { subcategory_id, country_code, is_active, custom_settings } = req.body;

        const result = await dbService.query(`
            INSERT INTO country_subcategories (subcategory_id, country_code, is_active, custom_settings)
            VALUES ($1, $2, $3, $4)
            RETURNING *
        `, [subcategory_id, country_code, is_active || true, custom_settings || {}]);

        res.status(201).json({
            success: true,
            message: 'Country subcategory created successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error creating country subcategory:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create country subcategory'
        });
    }
});

// Update country subcategory
router.put('/:id', authService.authMiddleware(), async (req, res) => {
    try {
        const { id } = req.params;
        const { subcategory_id, country_code, is_active, custom_settings } = req.body;

        const result = await dbService.query(`
            UPDATE country_subcategories 
            SET subcategory_id = $1, country_code = $2, is_active = $3, 
                custom_settings = $4, updated_at = CURRENT_TIMESTAMP
            WHERE id = $5
            RETURNING *
        `, [subcategory_id, country_code, is_active, custom_settings, id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Country subcategory not found'
            });
        }

        res.json({
            success: true,
            message: 'Country subcategory updated successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error updating country subcategory:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update country subcategory'
        });
    }
});

// Delete country subcategory
router.delete('/:id', authService.authMiddleware(), async (req, res) => {
    try {
        const { id } = req.params;

        const result = await dbService.query(`
            DELETE FROM country_subcategories WHERE id = $1 RETURNING *
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Country subcategory not found'
            });
        }

        res.json({
            success: true,
            message: 'Country subcategory deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting country subcategory:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete country subcategory'
        });
    }
});

module.exports = router;
