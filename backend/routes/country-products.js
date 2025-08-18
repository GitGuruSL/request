const express = require('express');
const router = express.Router();
const dbService = require('../services/database');
const authService = require('../services/auth');

// Get all country products
router.get('/', async (req, res) => {
    try {
        console.log('Fetching country products...');
        
        const result = await dbService.query(`
            SELECT 
                cp.*,
                mp.name as master_product_name,
                c.name as country_name
            FROM country_products cp
            LEFT JOIN master_products mp ON cp.master_product_id = mp.id
            LEFT JOIN countries c ON cp.country_code = c.code
            ORDER BY c.name, mp.name
        `);

        console.log(`Found ${result.rows.length} country products`);
        
        res.json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        console.error('Error fetching country products:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch country products'
        });
    }
});

// Get country product by ID
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await dbService.query(`
            SELECT 
                cp.*,
                mp.name as master_product_name,
                c.name as country_name
            FROM country_products cp
            LEFT JOIN master_products mp ON cp.master_product_id = mp.id
            LEFT JOIN countries c ON cp.country_code = c.code
            WHERE cp.id = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Country product not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error fetching country product:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch country product'
        });
    }
});

// Create new country product
router.post('/', authService.authMiddleware(), async (req, res) => {
    try {
        const { master_product_id, country_code, is_active, custom_data } = req.body;

        const result = await dbService.query(`
            INSERT INTO country_products (master_product_id, country_code, is_active, custom_data)
            VALUES ($1, $2, $3, $4)
            RETURNING *
        `, [master_product_id, country_code, is_active || true, custom_data || {}]);

        res.status(201).json({
            success: true,
            message: 'Country product created successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error creating country product:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create country product'
        });
    }
});

// Update country product
router.put('/:id', authService.authMiddleware(), async (req, res) => {
    try {
        const { id } = req.params;
        const { master_product_id, country_code, is_active, custom_data } = req.body;

        const result = await dbService.query(`
            UPDATE country_products 
            SET master_product_id = $1, country_code = $2, is_active = $3, 
                custom_data = $4, updated_at = CURRENT_TIMESTAMP
            WHERE id = $5
            RETURNING *
        `, [master_product_id, country_code, is_active, custom_data, id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Country product not found'
            });
        }

        res.json({
            success: true,
            message: 'Country product updated successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error updating country product:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update country product'
        });
    }
});

// Delete country product
router.delete('/:id', authService.authMiddleware(), async (req, res) => {
    try {
        const { id } = req.params;

        const result = await dbService.query(`
            DELETE FROM country_products WHERE id = $1 RETURNING *
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Country product not found'
            });
        }

        res.json({
            success: true,
            message: 'Country product deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting country product:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete country product'
        });
    }
});

module.exports = router;
