const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const dbService = require('./database');

class AuthService {
    constructor() {
        this.jwtSecret = process.env.JWT_SECRET || 'your-super-secret-jwt-key';
        this.jwtExpiry = process.env.JWT_EXPIRY || '24h';
        this.otpExpiry = 5 * 60 * 1000; // 5 minutes in milliseconds
    }

    /**
     * Generate JWT token
     */
    generateToken(user) {
        const payload = {
            userId: user.id,
            email: user.email,
            phone: user.phone,
            role: user.role,
            verified: user.email_verified || user.phone_verified
        };

        return jwt.sign(payload, this.jwtSecret, { expiresIn: this.jwtExpiry });
    }

    /**
     * Verify JWT token
     */
    verifyToken(token) {
        try {
            return jwt.verify(token, this.jwtSecret);
        } catch (error) {
            throw new Error('Invalid or expired token');
        }
    }

    /**
     * Hash password
     */
    async hashPassword(password) {
        const saltRounds = 12;
        return await bcrypt.hash(password, saltRounds);
    }

    /**
     * Verify password
     */
    async verifyPassword(password, hashedPassword) {
        return await bcrypt.compare(password, hashedPassword);
    }

    /**
     * Generate OTP
     */
    generateOTP() {
        return Math.floor(100000 + Math.random() * 900000).toString();
    }

    /**
     * Register new user
     */
    async register(userData) {
        const { email, phone, password, displayName, role = 'user' } = userData;

        // Validate required fields
        if (!email && !phone) {
            throw new Error('Either email or phone is required');
        }

        if (password && password.length < 6) {
            throw new Error('Password must be at least 6 characters');
        }

        // Check if user already exists
        let existingUser = null;
        if (email) {
            existingUser = await dbService.findMany('users', { email });
        }
        if (!existingUser && phone) {
            existingUser = await dbService.findMany('users', { phone });
        }

        if (existingUser && existingUser.length > 0) {
            throw new Error('User already exists with this email or phone');
        }

        // Hash password if provided
        const hashedPassword = password ? await this.hashPassword(password) : null;

        // Create user
        const newUser = await dbService.insert('users', {
            email: email || null,
            phone: phone || null,
            password_hash: hashedPassword,
            display_name: displayName || null,
            role,
            is_active: true,
            email_verified: false,
            phone_verified: false,
            country_code: 'LK',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        });

        // Generate token
        const token = this.generateToken(newUser);

        return {
            user: this.sanitizeUser(newUser),
            token
        };
    }

    /**
     * Login user
     */
    async login(loginData) {
        const { email, phone, password } = loginData;

        if (!email && !phone) {
            throw new Error('Email or phone is required');
        }

        // Find user
        let user = null;
        if (email) {
            const users = await dbService.findMany('users', { email });
            user = users[0];
        } else if (phone) {
            const users = await dbService.findMany('users', { phone });
            user = users[0];
        }

        if (!user) {
            throw new Error('User not found');
        }

        if (!user.is_active) {
            throw new Error('Account is deactivated');
        }

        // Verify password if provided
        if (password) {
            if (!user.password_hash) {
                throw new Error('Password login not available for this account');
            }

            const isValidPassword = await this.verifyPassword(password, user.password_hash);
            if (!isValidPassword) {
                throw new Error('Invalid password');
            }
        }

        // Generate token
        const token = this.generateToken(user);

        return {
            user: this.sanitizeUser(user),
            token
        };
    }

    /**
     * Send OTP for email verification
     */
    async sendEmailOTP(email) {
        const otp = this.generateOTP();
        const expiresAt = new Date(Date.now() + this.otpExpiry);

        // Store OTP in database
        await dbService.query(`
            INSERT INTO email_otp_verifications (email, otp, expires_at, created_at)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (email) 
            DO UPDATE SET otp = $2, expires_at = $3, created_at = $4, attempts = 0
        `, [email, otp, expiresAt, new Date()]);

        // TODO: Send email via AWS SES or your email service
        console.log(`Email OTP for ${email}: ${otp}`);

        return { message: 'OTP sent to email', otpSent: true };
    }

    /**
     * Send OTP for phone verification
     */
    async sendPhoneOTP(phone) {
        const otp = this.generateOTP();
        const expiresAt = new Date(Date.now() + this.otpExpiry);

        // Store OTP in database
        await dbService.query(`
            INSERT INTO phone_otp_verifications (phone, otp, expires_at, created_at)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (phone) 
            DO UPDATE SET otp = $2, expires_at = $3, created_at = $4, attempts = 0
        `, [phone, otp, expiresAt, new Date()]);

        // TODO: Send SMS via your SMS service
        console.log(`Phone OTP for ${phone}: ${otp}`);

        return { message: 'OTP sent to phone', otpSent: true };
    }

    /**
     * Verify email OTP
     */
    async verifyEmailOTP(email, otp) {
        const result = await dbService.query(`
            SELECT * FROM email_otp_verifications 
            WHERE email = $1 AND otp = $2 AND expires_at > NOW() AND verified = false
        `, [email, otp]);

        if (result.rows.length === 0) {
            // Increment attempts
            await dbService.query(`
                UPDATE email_otp_verifications 
                SET attempts = attempts + 1 
                WHERE email = $1
            `, [email]);
            
            throw new Error('Invalid or expired OTP');
        }

        // Mark OTP as verified
        await dbService.query(`
            UPDATE email_otp_verifications 
            SET verified = true, verified_at = NOW() 
            WHERE email = $1
        `, [email]);

        // Update user email verification status
        await dbService.query(`
            UPDATE users 
            SET email_verified = true, updated_at = NOW() 
            WHERE email = $1
        `, [email]);

        return { message: 'Email verified successfully', verified: true };
    }

    /**
     * Verify phone OTP
     */
    async verifyPhoneOTP(phone, otp) {
        const result = await dbService.query(`
            SELECT * FROM phone_otp_verifications 
            WHERE phone = $1 AND otp = $2 AND expires_at > NOW() AND verified = false
        `, [phone, otp]);

        if (result.rows.length === 0) {
            // Increment attempts
            await dbService.query(`
                UPDATE phone_otp_verifications 
                SET attempts = attempts + 1 
                WHERE phone = $1
            `, [phone]);
            
            throw new Error('Invalid or expired OTP');
        }

        // Mark OTP as verified
        await dbService.query(`
            UPDATE phone_otp_verifications 
            SET verified = true, verified_at = NOW() 
            WHERE phone = $1
        `, [phone]);

        // Update user phone verification status
        await dbService.query(`
            UPDATE users 
            SET phone_verified = true, updated_at = NOW() 
            WHERE phone = $1
        `, [phone]);

        return { message: 'Phone verified successfully', verified: true };
    }

    /**
     * Update user profile
     */
    async updateProfile(userId, updateData) {
        const { displayName, photoUrl } = updateData;
        
        const user = await dbService.update('users', userId, {
            display_name: displayName,
            photo_url: photoUrl
        });

        return this.sanitizeUser(user);
    }

    /**
     * Change password
     */
    async changePassword(userId, currentPassword, newPassword) {
        const user = await dbService.findById('users', userId);
        
        if (!user) {
            throw new Error('User not found');
        }

        if (user.password_hash) {
            const isValidPassword = await this.verifyPassword(currentPassword, user.password_hash);
            if (!isValidPassword) {
                throw new Error('Current password is incorrect');
            }
        }

        if (newPassword.length < 6) {
            throw new Error('New password must be at least 6 characters');
        }

        const hashedPassword = await this.hashPassword(newPassword);
        
        await dbService.update('users', userId, {
            password_hash: hashedPassword
        });

        return { message: 'Password updated successfully' };
    }

    /**
     * Remove sensitive data from user object
     */
    sanitizeUser(user) {
        if (!user) return null;
        
        const { password_hash, ...sanitizedUser } = user;
        return sanitizedUser;
    }

    /**
     * Middleware to verify JWT token
     */
    authMiddleware() {
        return async (req, res, next) => {
            try {
                const authHeader = req.headers.authorization;
                
                if (!authHeader || !authHeader.startsWith('Bearer ')) {
                    return res.status(401).json({ error: 'No token provided' });
                }

                const token = authHeader.substring(7);
                const decoded = this.verifyToken(token);
                
                // Get user from database
                const user = await dbService.findById('users', decoded.userId);
                if (!user || !user.is_active) {
                    return res.status(401).json({ error: 'User not found or inactive' });
                }

                req.user = this.sanitizeUser(user);
                next();
            } catch (error) {
                res.status(401).json({ error: error.message });
            }
        };
    }

    /**
     * Middleware to check user role
     */
    roleMiddleware(requiredRoles) {
        return (req, res, next) => {
            if (!req.user) {
                return res.status(401).json({ error: 'Authentication required' });
            }

            const userRole = req.user.role;
            if (!requiredRoles.includes(userRole)) {
                return res.status(403).json({ error: 'Insufficient permissions' });
            }

            next();
        };
    }
}

module.exports = new AuthService();
