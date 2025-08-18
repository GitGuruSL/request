const express = require('express');
const authService = require('../services/auth');
const dbService = require('../services/database');

const router = express.Router();

/**
 * @route POST /api/auth/register
 * @desc Register a new user
 */
router.post('/register', async (req, res) => {
    try {
        const { email, phone, password, displayName } = req.body;

        // Validate input
        if (!email && !phone) {
            return res.status(400).json({ 
                error: 'Either email or phone is required' 
            });
        }

        const result = await authService.register({
            email,
            phone,
            password,
            displayName
        });

        res.status(201).json({
            success: true,
            message: 'User registered successfully',
            ...result
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route POST /api/auth/login
 * @desc Login user
 */
router.post('/login', async (req, res) => {
    try {
        const { email, phone, password } = req.body;

        const result = await authService.login({
            email,
            phone,
            password
        });

        res.json({
            success: true,
            message: 'Login successful',
            data: result
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(401).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route POST /api/auth/refresh
 * @desc Rotate refresh token and issue new access & refresh tokens
 */
router.post('/refresh', async (req, res) => {
    try {
        const { userId, refreshToken } = req.body;
        if (!userId || !refreshToken) {
            return res.status(400).json({ success: false, error: 'userId and refreshToken required' });
        }
        // Verify user exists
        const users = await authService.sanitizeUser(await require('../services/database').findById('users', userId));
        if (!users) return res.status(401).json({ success: false, error: 'Invalid user' });
        const newRawRefresh = await authService.verifyAndRotateRefreshToken(userId, refreshToken);
        const newAccess = authService.generateToken({ id: userId, email: users.email, phone: users.phone, role: users.role, email_verified: users.email_verified, phone_verified: users.phone_verified });
        res.json({ success: true, message: 'Token refreshed', data: { token: newAccess, refreshToken: newRawRefresh } });
    } catch (error) {
        console.error('Refresh error:', error);
        res.status(401).json({ success: false, error: error.message });
    }
});

/**
 * @route POST /api/auth/send-email-otp
 * @desc Send OTP to email
 */
router.post('/send-email-otp', async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ 
                error: 'Email is required' 
            });
        }

    const result = await authService.sendEmailOTP(email);
    res.json({ success: true, message: result.message, channel: result.channel, email: result.email });
    } catch (error) {
        console.error('Send email OTP error:', error);
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route POST /api/auth/send-phone-otp
 * @desc Send OTP to phone
 */
router.post('/send-phone-otp', async (req, res) => {
    try {
        const { phone, countryCode } = req.body;

        if (!phone) {
            return res.status(400).json({ 
                error: 'Phone number is required' 
            });
        }

        const result = await authService.sendPhoneOTP(phone, countryCode);

        res.json({
            success: true,
            message: result.message,
            channel: result.channel,
            sms: result.sms
        });
    } catch (error) {
        console.error('Send phone OTP error:', error);
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route POST /api/auth/verify-email-otp
 * @desc Verify email OTP
 */
router.post('/verify-email-otp', async (req, res) => {
    try {
        const { email, otp } = req.body;

        if (!email || !otp) {
            return res.status(400).json({ 
                error: 'Email and OTP are required' 
            });
        }

        const result = await authService.verifyEmailOTP(email, otp);
        res.json({
            success: true,
            message: result.message,
            data: {
                verified: result.verified,
                user: result.user,
                token: result.token,
                refreshToken: result.refreshToken
            }
        });
    } catch (error) {
        console.error('Verify email OTP error:', error);
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route POST /api/auth/verify-phone-otp
 * @desc Verify phone OTP
 */
router.post('/verify-phone-otp', async (req, res) => {
    try {
        const { phone, otp } = req.body;

        if (!phone || !otp) {
            return res.status(400).json({ 
                error: 'Phone and OTP are required' 
            });
        }

        const result = await authService.verifyPhoneOTP(phone, otp);
        res.json({
            success: true,
            message: result.message,
            data: {
                verified: result.verified,
                user: result.user,
                token: result.token,
                refreshToken: result.refreshToken
            }
        });
    } catch (error) {
        console.error('Verify phone OTP error:', error);
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route GET /api/auth/profile
 * @desc Get user profile
 */
router.get('/profile', authService.authMiddleware(), async (req, res) => {
    try {
        res.json({
            success: true,
            data: { ...req.user, permissions: req.user.permissions || {} }
        });
    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route PUT /api/auth/profile
 * @desc Update user profile
 */
router.put('/profile', authService.authMiddleware(), async (req, res) => {
    try {
        const { displayName, photoUrl, firstName, lastName, first_name, last_name, password } = req.body;

        // Support both camelCase and snake_case field names
        const updateData = {
            displayName,
            photoUrl,
            firstName: firstName || first_name,
            lastName: lastName || last_name,
            password
        };

        // Remove undefined values
        Object.keys(updateData).forEach(key => {
            if (updateData[key] === undefined) {
                delete updateData[key];
            }
        });

        const updatedUser = await authService.updateProfile(req.user.id, updateData);

        res.json({
            success: true,
            message: 'Profile updated successfully',
            user: updatedUser
        });
    } catch (error) {
        console.error('Update profile error:', error);
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route POST /api/auth/change-password
 * @desc Change user password
 */
router.post('/change-password', authService.authMiddleware(), async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!newPassword) {
            return res.status(400).json({ 
                error: 'New password is required' 
            });
        }

        const result = await authService.changePassword(
            req.user.id, 
            currentPassword, 
            newPassword
        );

        res.json({
            success: true,
            message: result.message
        });
    } catch (error) {
        console.error('Change password error:', error);
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route POST /api/auth/logout
 * @desc Logout user (client-side token removal)
 */
router.post('/logout', authService.authMiddleware(), async (req, res) => {
    try {
        // In JWT, logout is handled client-side by removing the token
        // For enhanced security, you could implement a token blacklist
        
        res.json({
            success: true,
            message: 'Logged out successfully'
        });
    } catch (error) {
        console.error('Logout error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route POST /api/auth/dev/seed-admin
 * @desc Development helper: create a default super admin user if none exists
 * Body (optional): { email, password, displayName }
 * Safeguards: Disabled in production (NODE_ENV==='production')
 */
router.post('/dev/seed-admin', async (req, res) => {
    try {
        if (process.env.NODE_ENV === 'production') {
            return res.status(403).json({ success: false, error: 'Not available in production' });
        }
        const {
            email = 'admin@example.com',
            password = 'Admin123!',
            displayName = 'Super Admin'
        } = req.body || {};

        // Check existing super admin
        const existingAdmins = await dbService.query(`SELECT id, email FROM users WHERE role = 'super_admin' LIMIT 1`);
        if (existingAdmins.rows.length > 0) {
            return res.json({ success: true, message: 'Super admin already exists', data: existingAdmins.rows[0] });
        }

        // Check existing by email
        const existingByEmail = await dbService.findMany('users', { email });
        if (existingByEmail.length > 0) {
            // Promote existing user
            const promoted = await dbService.update('users', existingByEmail[0].id, {
                role: 'super_admin',
                email_verified: true,
                is_active: true,
                updated_at: new Date().toISOString()
            });
            const token = authService.generateToken(promoted);
            const refreshToken = await authService.generateAndStoreRefreshToken(promoted.id);
            return res.json({ success: true, message: 'Existing user promoted to super_admin', data: { user: authService.sanitizeUser(promoted), token, refreshToken } });
        }

        // Create fresh user (manual to ensure role & verification flags)
        const passwordHash = password ? await authService.hashPassword(password) : null;
        const newUser = await dbService.insert('users', {
            email,
            phone: null,
            password_hash: passwordHash,
            display_name: displayName,
            first_name: displayName.split(' ')[0],
            last_name: displayName.split(' ').slice(1).join(' ') || null,
            role: 'super_admin',
            is_active: true,
            email_verified: true,
            phone_verified: false,
            country_code: 'LK',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        });
        const token = authService.generateToken(newUser);
        const refreshToken = await authService.generateAndStoreRefreshToken(newUser.id);
        res.status(201).json({ success: true, message: 'Super admin user created', data: { user: authService.sanitizeUser(newUser), token, refreshToken, credentials: { email, password } } });
    } catch (error) {
        console.error('Seed admin error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;
