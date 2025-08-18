const express = require('express');
const router = express.Router();
const dbService = require('../services/database');
const authService = require('../services/auth');

// Get all country variable types
router.get('/', async (req, res) => {
    try {
        console.log('Fetching country variable types...');
        
        const result = await dbService.query(`
            SELECT 
                cvt.*,
                v.name as variable_name,
                v.type as variable_type,
                co.name as country_name
            FROM country_variable_types cvt
            LEFT JOIN variables v ON cvt.variable_id = v.id
            LEFT JOIN countries co ON cvt.country_code = co.code
            ORDER BY co.name, v.name
        `);

        console.log(`Found ${result.rows.length} country variable types`);
        
        res.json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        console.error('Error fetching country variable types:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch country variable types'
        });
    }
});

// Get country variable type by ID
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await dbService.query(`
            SELECT 
                cvt.*,
                v.name as variable_name,
                v.type as variable_type,
                co.name as country_name
            FROM country_variable_types cvt
            LEFT JOIN variables v ON cvt.variable_id = v.id
            LEFT JOIN countries co ON cvt.country_code = co.code
            WHERE cvt.id = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Country variable type not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error fetching country variable type:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch country variable type'
        });
    }
});

// Create new country variable type
router.post('/', authService.authMiddleware(), async (req, res) => {
    try {
        const { variable_id, country_code, is_active, custom_settings } = req.body;

        const result = await dbService.query(`
            INSERT INTO country_variable_types (variable_id, country_code, is_active, custom_settings)
            VALUES ($1, $2, $3, $4)
            RETURNING *
        `, [variable_id, country_code, is_active || true, custom_settings || {}]);

        res.status(201).json({
            success: true,
            message: 'Country variable type created successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error creating country variable type:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create country variable type'
        });
    }
});

// Update country variable type
router.put('/:id', authService.authMiddleware(), async (req, res) => {
    try {
        const { id } = req.params;
        const { variable_id, country_code, is_active, custom_settings } = req.body;

        const result = await dbService.query(`
            UPDATE country_variable_types 
            SET variable_id = $1, country_code = $2, is_active = $3, 
                custom_settings = $4, updated_at = CURRENT_TIMESTAMP
            WHERE id = $5
            RETURNING *
        `, [variable_id, country_code, is_active, custom_settings, id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Country variable type not found'
            });
        }

        res.json({
            success: true,
            message: 'Country variable type updated successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error updating country variable type:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update country variable type'
        });
    }
});

// Delete country variable type
router.delete('/:id', authService.authMiddleware(), async (req, res) => {
    try {
        const { id } = req.params;

        const result = await dbService.query(`
            DELETE FROM country_variable_types WHERE id = $1 RETURNING *
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Country variable type not found'
            });
        }

        res.json({
            success: true,
            message: 'Country variable type deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting country variable type:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete country variable type'
        });
    }
});

module.exports = router;
