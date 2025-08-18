const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const dbService = require('./database');
const emailService = require('./email');
const smsService = require('./sms');

class AuthService {
    constructor() {
        this.jwtSecret = process.env.JWT_SECRET || 'your-super-secret-jwt-key';
        this.jwtExpiry = process.env.JWT_EXPIRY || '24h';
        this.otpExpiry = 5 * 60 * 1000; // 5 minutes in milliseconds
    this.refreshExpiryMs = 30 * 24 * 60 * 60 * 1000; // 30 days
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
         * Generate a secure refresh token (random string) and store hashed version
         */
        async generateAndStoreRefreshToken(userId) {
                const raw = crypto.randomBytes(48).toString('hex');
                const hash = crypto.createHash('sha256').update(raw).digest('hex');
                // Persist (one active per user for simplicity) - upsert pattern
                await dbService.query(`
                    INSERT INTO user_refresh_tokens (user_id, token_hash, expires_at, created_at)
                    VALUES ($1,$2,$3,NOW())
                    ON CONFLICT (user_id)
                    DO UPDATE SET token_hash = EXCLUDED.token_hash, expires_at = EXCLUDED.expires_at, created_at = NOW()
                `, [userId, hash, new Date(Date.now() + this.refreshExpiryMs)]);
                return raw; // return raw to client (only time we reveal it)
        }

        async verifyAndRotateRefreshToken(userId, providedToken) {
                const hash = crypto.createHash('sha256').update(providedToken).digest('hex');
                const row = await dbService.query(`
                    SELECT * FROM user_refresh_tokens WHERE user_id=$1 AND token_hash=$2 AND expires_at > NOW()
                `, [userId, hash]);
                if (row.rows.length === 0) throw new Error('Invalid or expired refresh token');
                // Rotate (invalidate old by replacing)
                return await this.generateAndStoreRefreshToken(userId);
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
        const { email, phone, password, displayName, role = 'user', first_name, last_name } = userData;

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
            first_name: first_name || (displayName ? displayName.split(' ')[0] : null),
            last_name: last_name || (displayName ? displayName.split(' ').slice(1).join(' ') : null),
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
    const refreshToken = await this.generateAndStoreRefreshToken(newUser.id);

        return {
            user: this.sanitizeUser(newUser),
            token,
            refreshToken
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

        // Find user in users table first, then check admin_users table
        let user = null;
        if (email) {
            const users = await dbService.findMany('users', { email });
            user = users[0];
            
            // If not found in users table, check admin_users table
            if (!user) {
                const adminUsers = await dbService.findMany('admin_users', { email });
                if (adminUsers[0]) {
                    // Convert admin_users format to users format
                    const admin = adminUsers[0];
                    user = {
                        id: admin.id,
                        email: admin.email,
                        phone: null, // admin_users doesn't have phone
                        password_hash: admin.password_hash, // copy password_hash from admin_users
                        display_name: admin.name,
                        role: admin.role,
                        is_active: admin.is_active,
                        email_verified: true, // assume admin emails are verified
                        phone_verified: false,
                        country_code: 'LK', // default
                        permissions: admin.permissions,
                        created_at: admin.created_at,
                        updated_at: admin.updated_at
                    };
                }
            }
        } else if (phone) {
            const users = await dbService.findMany('users', { phone });
            user = users[0];
            // admin_users table doesn't have phone numbers, so only check users table
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
                // For admin_users without password_hash, check if this is the default admin and set password
                if (user.email === 'superadmin@request.lk' && password === 'StrongPassword123!') {
                    // Allow login and set password_hash in admin_users table
                    const hashedPassword = await this.hashPassword(password);
                    if (user.role === 'super_admin') {
                        // Update admin_users table with password_hash
                        await dbService.query(
                            'UPDATE admin_users SET password_hash = $1 WHERE email = $2',
                            [hashedPassword, user.email]
                        );
                        user.password_hash = hashedPassword;
                    }
                } else {
                    throw new Error('Password login not available for this account');
                }
            } else {
                const isValidPassword = await this.verifyPassword(password, user.password_hash);
                if (!isValidPassword) {
                    throw new Error('Invalid password');
                }
            }
        }

        // Generate token
        const token = this.generateToken(user);
        
        // Skip refresh tokens for admin users (they exist in admin_users table, not users table)
        let refreshToken = null;
        if (user.role !== 'super_admin' && user.role !== 'admin' && user.role !== 'business_admin') {
            refreshToken = await this.generateAndStoreRefreshToken(user.id);
        }
        
        return {
            user: this.sanitizeUser(user),
            token,
            refreshToken
        };
    }

    /**
     * Send OTP for email verification
     */
    async sendEmailOTP(email) {
        const otp = this.generateOTP();
        const expiresAt = new Date(Date.now() + this.otpExpiry);

                // Ensure table exists (defensive in case migrations not run yet)
                await dbService.query(`CREATE TABLE IF NOT EXISTS email_otp_verifications (
                    email VARCHAR(255) PRIMARY KEY,
                    otp VARCHAR(6) NOT NULL,
                    expires_at TIMESTAMPTZ NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                    attempts INT NOT NULL DEFAULT 0,
                    verified BOOLEAN NOT NULL DEFAULT FALSE,
                    verified_at TIMESTAMPTZ
                )`);
    // Add missing columns if the table existed without them (older baseline)
    await dbService.query(`ALTER TABLE email_otp_verifications ADD COLUMN IF NOT EXISTS verified BOOLEAN NOT NULL DEFAULT FALSE`);
    await dbService.query(`ALTER TABLE email_otp_verifications ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ`);

                // Store OTP (manual UPSERT to tolerate environments where primary key wasn't created yet)
                await dbService.query(`
                    WITH updated AS (
                        UPDATE email_otp_verifications
                            SET otp = $2, expires_at = $3, created_at = $4, attempts = 0, verified = FALSE
                            WHERE email = $1
                            RETURNING email
                    )
                    INSERT INTO email_otp_verifications (email, otp, expires_at, created_at)
                    SELECT $1, $2, $3, $4
                    WHERE NOT EXISTS (SELECT 1 FROM updated);
                `, [email, otp, expiresAt, new Date()]);

        // Send email via SES (with dev fallback handled inside email service)
        let emailMeta = { messageId: null, fallback: false, error: null };
        try {
            const sendRes = await emailService.sendOTP(email, otp, 'login');
            emailMeta.messageId = sendRes.messageId;
            emailMeta.fallback = !!sendRes.fallback;
            emailMeta.error = sendRes.error || null;
        } catch (e) {
            emailMeta.error = e.message;
            console.warn('Email send failed, OTP logged for debugging:', e.message);
            console.log(`Email OTP fallback (dev) for ${email}: ${otp}`);
        }

        return { message: 'OTP sent to email', otpSent: true, channel: 'email', email: emailMeta };
    }

    /**
     * Send OTP for phone verification
     */
    async sendPhoneOTP(phone, countryCode = 'LK') {
        const otp = this.generateOTP();
        const expiresAt = new Date(Date.now() + this.otpExpiry);

        await dbService.query(`CREATE TABLE IF NOT EXISTS phone_otp_verifications (
                    phone VARCHAR(32) PRIMARY KEY,
                    otp VARCHAR(6) NOT NULL,
                    expires_at TIMESTAMPTZ NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                    attempts INT NOT NULL DEFAULT 0,
                    verified BOOLEAN NOT NULL DEFAULT FALSE,
                    verified_at TIMESTAMPTZ
                )`);
        await dbService.query(`ALTER TABLE phone_otp_verifications ADD COLUMN IF NOT EXISTS verified BOOLEAN NOT NULL DEFAULT FALSE`);
        await dbService.query(`ALTER TABLE phone_otp_verifications ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ`);

        await dbService.query(`
                    WITH updated AS (
                        UPDATE phone_otp_verifications
                            SET otp = $2, expires_at = $3, created_at = $4, attempts = 0, verified = FALSE
                            WHERE phone = $1
                            RETURNING phone
                    )
                    INSERT INTO phone_otp_verifications (phone, otp, expires_at, created_at)
                    SELECT $1, $2, $3, $4
                    WHERE NOT EXISTS (SELECT 1 FROM updated);
                `, [phone, otp, expiresAt, new Date()]);

        if (!countryCode) {
            if (phone.startsWith('+94')) countryCode = 'LK';
        }
        let smsMeta;
        try {
            smsMeta = await smsService.sendOTP({ phone, otp, countryCode });
        } catch (e) {
            console.warn('[SMS] send failed, fallback dev log:', e.message);
            console.log(`[SMS][FALLBACK-ERROR] OTP for ${phone}: ${otp}`);
            smsMeta = { success: false, error: e.message, provider: 'dev', fallback: true };
        }
        return { message: 'OTP sent to phone', otpSent: true, channel: 'sms', sms: smsMeta };
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
        // Fetch updated user
        const userRows = await dbService.findMany('users', { email });
        const user = userRows[0];
        let token = null; let refreshToken = null;
        if (user) {
            token = this.generateToken(user);
            refreshToken = await this.generateAndStoreRefreshToken(user.id);
        }
        return { message: 'Email verified successfully', verified: true, user: this.sanitizeUser(user), token, refreshToken };
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
        // Fetch updated user
        const userRows = await dbService.findMany('users', { phone });
        const user = userRows[0];
        let token = null; let refreshToken = null;
        if (user) {
            token = this.generateToken(user);
            refreshToken = await this.generateAndStoreRefreshToken(user.id);
        }
        return { message: 'Phone verified successfully', verified: true, user: this.sanitizeUser(user), token, refreshToken };
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

    /**
     * Alias for roleMiddleware for convenience
     */
    requireRole(requiredRoles) {
        return this.roleMiddleware(requiredRoles);
    }

    /**
     * Permission middleware (expects users.permissions JSONB column)
     */
    permissionMiddleware(permissionKey) {
        return (req, res, next) => {
            if (!req.user) {
                return res.status(401).json({ error: 'Authentication required' });
            }
            const perms = req.user.permissions || req.user.permission || req.user.perms || {};
            if (perms[permissionKey] === true) return next();
            return res.status(403).json({ error: 'Permission denied' });
        };
    }

    requirePermission(permissionKey) { return this.permissionMiddleware(permissionKey); }
}

module.exports = new AuthService();
