// Add these authentication endpoints to your existing Node.js backend

const express = require('express');
const router = express.Router();
const { pool } = require('../database'); // Your existing database connection
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

// JWT Secret (use your existing one or set in environment)
const JWT_SECRET = process.env.JWT_SECRET || 'your-jwt-secret-key';

// 1. Check if user exists (needed for login flow routing)
router.post('/check-user-exists', async (req, res) => {
  try {
    const { emailOrPhone } = req.body;

    if (!emailOrPhone) {
      return res.status(400).json({
        success: false,
        message: 'Email or phone number is required'
      });
    }

    const result = await pool.query(
      'SELECT id, email, phone FROM users WHERE email = $1 OR phone = $1 AND is_active = true',
      [emailOrPhone]
    );

    res.json({
      exists: result.rows.length > 0,
      message: result.rows.length > 0 ? 'User found' : 'User not found'
    });

  } catch (error) {
    console.error('Check user exists error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// 2. Send OTP (for new user registration)
router.post('/send-otp', async (req, res) => {
  try {
    const { emailOrPhone, isEmail, countryCode } = req.body;

    if (!emailOrPhone) {
      return res.status(400).json({
        success: false,
        message: 'Email or phone number is required'
      });
    }

    // Generate 6-digit OTP
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Generate secure token for OTP verification
    const otpToken = crypto.randomBytes(32).toString('hex');
    
    // Set expiration time (10 minutes from now)
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    // Store OTP in database
    await pool.query(
      `INSERT INTO otp_tokens (email_or_phone, otp_code, token_hash, expires_at, purpose)
       VALUES ($1, $2, $3, $4, $5)`,
      [emailOrPhone, otpCode, otpToken, expiresAt, 'registration']
    );

    // TODO: Send actual OTP via SMS/Email
    if (isEmail) {
      // Send email OTP using AWS SES
      console.log(`Email OTP for ${emailOrPhone}: ${otpCode}`);
      // await sendEmailOTP(emailOrPhone, otpCode);
    } else {
      // Send SMS OTP using your SMS provider
      console.log(`SMS OTP for ${emailOrPhone}: ${otpCode}`);
      // await sendSMSOTP(emailOrPhone, otpCode, countryCode);
    }

    res.json({
      success: true,
      otpToken: otpToken,
      message: `OTP sent to ${emailOrPhone}`
    });

  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send OTP'
    });
  }
});

// 3. Verify OTP (for new user registration)
router.post('/verify-otp', async (req, res) => {
  try {
    const { emailOrPhone, otp, otpToken } = req.body;

    if (!emailOrPhone || !otp || !otpToken) {
      return res.status(400).json({
        success: false,
        message: 'Email/phone, OTP, and token are required'
      });
    }

    // Find valid OTP token
    const result = await pool.query(
      `SELECT * FROM otp_tokens 
       WHERE email_or_phone = $1 AND token_hash = $2 AND used = false AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
      [emailOrPhone, otpToken]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP token'
      });
    }

    const otpRecord = result.rows[0];

    // Verify OTP code
    if (otpRecord.otp_code !== otp) {
      // Increment attempts
      await pool.query(
        'UPDATE otp_tokens SET attempts = attempts + 1 WHERE id = $1',
        [otpRecord.id]
      );

      return res.status(400).json({
        success: false,
        message: 'Invalid OTP code'
      });
    }

    // Mark OTP as used
    await pool.query(
      'UPDATE otp_tokens SET used = true WHERE id = $1',
      [otpRecord.id]
    );

    // OTP verified successfully - return success
    res.json({
      success: true,
      verified: true,
      message: 'OTP verified successfully'
    });

  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({
      success: false,
      message: 'OTP verification failed'
    });
  }
});

// 4. Update existing login endpoint for Flutter compatibility
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Find user by email or phone
    const userResult = await pool.query(
      'SELECT * FROM users WHERE (email = $1 OR phone = $1) AND is_active = true',
      [email]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const user = userResult.rows[0];

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email,
        role: user.role,
        countryCode: user.country_code
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Remove password from response
    const { password_hash, ...userWithoutPassword } = user;

    res.json({
      success: true,
      message: 'Login successful',
      token: token,
      user: userWithoutPassword
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed'
    });
  }
});

// 5. Update existing register endpoint for Flutter compatibility
router.post('/register', async (req, res) => {
  try {
    const { email, password, display_name, phone } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Check if user already exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1 OR phone = $2',
      [email, phone]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'User already exists'
      });
    }

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create user
    const userResult = await pool.query(
      `INSERT INTO users (email, password_hash, display_name, phone, country_code, email_verified, phone_verified)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, email, phone, display_name, email_verified, phone_verified, is_active, role, country_code, created_at, updated_at`,
      [email, hashedPassword, display_name, phone, 'LK', false, false]
    );

    const newUser = userResult.rows[0];

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: newUser.id, 
        email: newUser.email,
        role: newUser.role,
        countryCode: newUser.country_code
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token: token,
      user: newUser
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed'
    });
  }
});

module.exports = router;
