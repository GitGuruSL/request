const express = require('express');
const router = express.Router();
const dbService = require('../services/database');
const authService = require('../services/auth');

// Get all admin users
router.get('/', authService.authMiddleware(), async (req, res) => {
    try {
        console.log('Fetching admin users...');
        
        const result = await dbService.query(`
            SELECT 
                au.*,
                c.name as country_name
            FROM admin_users au
            LEFT JOIN countries c ON au.country_code = c.code
            ORDER BY au.created_at DESC
        `);

        console.log(`Found ${result.rows.length} admin users`);
        
        res.json({
            success: true,
            data: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        console.error('Error fetching admin users:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch admin users'
        });
    }
});

// Get admin user by ID
router.get('/:id', authService.authMiddleware(), async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await dbService.query(`
            SELECT 
                au.*,
                c.name as country_name
            FROM admin_users au
            LEFT JOIN countries c ON au.country_code = c.code
            WHERE au.id = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Admin user not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error fetching admin user:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch admin user'
        });
    }
});

// Create new admin user (Super admin only)
router.post('/', authService.authMiddleware(), async (req, res) => {
    try {
        // Check if user is super admin
        if (req.user.role !== 'super_admin') {
            return res.status(403).json({
                success: false,
                error: 'Only super admins can create admin users'
            });
        }

        const { email, password, display_name, role, country_code, permissions, is_active } = req.body;

        // Hash password
        const hashedPassword = await authService.hashPassword(password);

        const result = await dbService.query(`
            INSERT INTO admin_users (email, password_hash, display_name, role, country_code, permissions, is_active)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
        `, [email, hashedPassword, display_name, role, country_code, permissions || {}, is_active !== false]);

        // Remove password hash from response
        const { password_hash, ...adminUser } = result.rows[0];

        res.status(201).json({
            success: true,
            message: 'Admin user created successfully',
            data: adminUser
        });
    } catch (error) {
        console.error('Error creating admin user:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create admin user'
        });
    }
});

// Update admin user
router.put('/:id', authService.authMiddleware(), async (req, res) => {
    try {
        const { id } = req.params;
        const { display_name, role, country_code, permissions, is_active } = req.body;

        // Check if user can update (super admin or updating their own profile)
        if (req.user.role !== 'super_admin' && req.user.id !== id) {
            return res.status(403).json({
                success: false,
                error: 'Insufficient permissions'
            });
        }

        const result = await dbService.query(`
            UPDATE admin_users 
            SET display_name = $1, role = $2, country_code = $3, 
                permissions = $4, is_active = $5, updated_at = CURRENT_TIMESTAMP
            WHERE id = $6
            RETURNING *
        `, [display_name, role, country_code, permissions, is_active, id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Admin user not found'
            });
        }

        // Remove password hash from response
        const { password_hash, ...adminUser } = result.rows[0];

        res.json({
            success: true,
            message: 'Admin user updated successfully',
            data: adminUser
        });
    } catch (error) {
        console.error('Error updating admin user:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update admin user'
        });
    }
});

// Delete admin user (Super admin only)
router.delete('/:id', authService.authMiddleware(), async (req, res) => {
    try {
        // Check if user is super admin
        if (req.user.role !== 'super_admin') {
            return res.status(403).json({
                success: false,
                error: 'Only super admins can delete admin users'
            });
        }

        const { id } = req.params;

        const result = await dbService.query(`
            DELETE FROM admin_users WHERE id = $1 RETURNING *
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Admin user not found'
            });
        }

        res.json({
            success: true,
            message: 'Admin user deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting admin user:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete admin user'
        });
    }
});

module.exports = router;
