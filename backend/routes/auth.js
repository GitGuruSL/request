const express = require('express');
const router = express.Router();
const authService = require('../services/auth'); // Import the auth service

// Register endpoint
router.post('/register', async (req, res) => {
    try {
        const result = await authService.register(req.body);
        res.json({
            success: true,
            message: 'User registered successfully',
            data: result
        });
    } catch (error) {
        console.error('Register error:', error.message);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

// Login endpoint
router.post('/login', async (req, res) => {
    try {
        const result = await authService.login(req.body);
        res.json({
            success: true,
            message: 'Login successful',
            data: result
        });
    } catch (error) {
        console.error('Login error:', error.message);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

// Send email OTP endpoint
router.post('/send-email-otp', async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email) {
            return res.status(400).json({
                success: false,
                message: 'Email is required'
            });
        }

        const result = await authService.sendEmailOTP(email);
        res.json({
            success: true,
            message: result.message,
            ...result
        });
    } catch (error) {
        console.error('Send email OTP error:', error.message);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// Send phone OTP endpoint
router.post('/send-phone-otp', async (req, res) => {
    try {
        const { phone, countryCode } = req.body;
        
        if (!phone) {
            return res.status(400).json({
                success: false,
                message: 'Phone number is required'
            });
        }

        const result = await authService.sendPhoneOTP(phone, countryCode);
        res.json({
            success: true,
            message: result.message,
            ...result
        });
    } catch (error) {
        console.error('Send phone OTP error:', error.message);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// Verify email OTP endpoint
router.post('/verify-email-otp', async (req, res) => {
    try {
        const { email, otp } = req.body;
        
        if (!email || !otp) {
            return res.status(400).json({
                success: false,
                message: 'Email and OTP are required'
            });
        }

        const result = await authService.verifyEmailOTP(email, otp);
        res.json({
            success: true,
            message: result.message,
            ...result
        });
    } catch (error) {
        console.error('Verify email OTP error:', error.message);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

// Verify phone OTP endpoint
router.post('/verify-phone-otp', async (req, res) => {
    try {
        const { phone, otp } = req.body;
        
        if (!phone || !otp) {
            return res.status(400).json({
                success: false,
                message: 'Phone and OTP are required'
            });
        }

        const result = await authService.verifyPhoneOTP(phone, otp);
        res.json({
            success: true,
            message: result.message,
            ...result
        });
    } catch (error) {
        console.error('Verify phone OTP error:', error.message);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

// Update profile endpoint
router.put('/profile', authService.authMiddleware(), async (req, res) => {
    try {
        const result = await authService.updateProfile(req.user.id, req.body);
        res.json({
            success: true,
            message: 'Profile updated successfully',
            data: result
        });
    } catch (error) {
        console.error('Update profile error:', error.message);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

// Change password endpoint
router.post('/change-password', authService.authMiddleware(), async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;
        const result = await authService.changePassword(req.user.id, currentPassword, newPassword);
        res.json({
            success: true,
            message: result.message
        });
    } catch (error) {
        console.error('Change password error:', error.message);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

// Get current user profile endpoint
router.get('/profile', authService.authMiddleware(), async (req, res) => {
    try {
        res.json({
            success: true,
            data: req.user
        });
    } catch (error) {
        console.error('Get profile error:', error.message);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// Refresh token endpoint
router.post('/refresh-token', async (req, res) => {
    try {
        const { refreshToken, userId } = req.body;
        
        if (!refreshToken || !userId) {
            return res.status(400).json({
                success: false,
                message: 'Refresh token and user ID are required'
            });
        }

        const newRefreshToken = await authService.verifyAndRotateRefreshToken(userId, refreshToken);
        res.json({
            success: true,
            refreshToken: newRefreshToken
        });
    } catch (error) {
        console.error('Refresh token error:', error.message);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
});

module.exports = router;
