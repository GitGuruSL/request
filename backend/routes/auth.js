const express = require('express');
const authService = require('../services/auth');

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
            data: result
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
        const { displayName, photoUrl } = req.body;

        const updatedUser = await authService.updateProfile(req.user.id, {
            displayName,
            photoUrl
        });

        res.json({
            success: true,
            message: 'Profile updated successfully',
            data: updatedUser
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

module.exports = router;
