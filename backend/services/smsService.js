const twilio = require('twilio');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const axios = require('axios');
const database = require('./database');
const crypto = require('crypto');

/**
 * 📱 SMS Service - Multi-provider SMS management system
 * Supports Twilio, AWS SNS, Vonage, and Local providers
 */
class SMSService {
  constructor() {
    this.providers = {
      twilio: TwilioProvider,
      aws: AWSSNSProvider,
      vonage: VonageProvider,
      local: LocalProvider,
      hutch_mobile: HutchMobileProvider
    };
  }

  /**
   * Get SMS configuration for a country (from sms_provider_configs table)
   */
  async getSMSConfig(countryCode) {
    try {
      const result = await database.query(
        'SELECT * FROM sms_provider_configs WHERE country_code = $1 AND is_active = true',
        [countryCode]
      );

      if (result.rows.length === 0) {
        throw new Error(`No active SMS provider configuration found for country: ${countryCode}. Please contact your country admin to set up SMS services.`);
      }

      return result.rows[0];
    } catch (error) {
      console.error('Error getting SMS config:', error);
      throw error;
    }
  }

  /**
   * Detect country from phone number
   */
  detectCountry(phoneNumber) {
    const cleanPhone = phoneNumber.replace(/[^\d+]/g, '');
    
    if (cleanPhone.startsWith('+94')) return 'LK'; // Sri Lanka
    if (cleanPhone.startsWith('+91')) return 'IN'; // India
    if (cleanPhone.startsWith('+1')) return 'US';   // USA
    if (cleanPhone.startsWith('+44')) return 'UK';  // UK
    if (cleanPhone.startsWith('+971')) return 'AE'; // UAE
    
    return 'LK'; // Default to Sri Lanka
  }

  /**
   * Send OTP via SMS
   */
  async sendOTP(phoneNumber, countryCode = null) {
    try {
      // Auto-detect country if not provided
      if (!countryCode) {
        countryCode = this.detectCountry(phoneNumber);
      }

      // Check rate limiting
      await this.checkRateLimit(phoneNumber);

      // Get SMS configuration
      const config = await this.getSMSConfig(countryCode);
      
      // Generate OTP
      const otp = this.generateOTP();
      const otpId = this.generateOTPId();
      
      // Get provider instance
      const Provider = this.providers[config.provider];
      if (!Provider) {
        throw new Error(`Unsupported provider: ${config.provider}`);
      }

      const provider = new Provider(this.formatProviderConfig(config));
      
      // Prepare message
      const message = `Your Request Marketplace verification code is: ${otp}. Valid for 5 minutes.`;
      
      // Send SMS
      const smsResult = await provider.sendSMS(phoneNumber, message);
      
      // Store OTP in database
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes
      await database.query(`
        INSERT INTO phone_otp_verifications 
        (otp_id, phone, otp, country_code, expires_at, attempts, max_attempts, created_at, provider_used)
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), $8)
      `, [otpId, phoneNumber, otp, countryCode, expiresAt, 0, 3, config.provider]);

      // Update cost tracking
      await this.updateCostTracking(countryCode, config.provider, smsResult.cost);

      console.log(`📱 OTP sent to ${phoneNumber} via ${config.provider}`);

      return {
        success: true,
        otpId,
        otpToken: otpId, // Add otpToken for Flutter app compatibility
        expiresIn: 300, // 5 minutes
        provider: config.provider,
        message: 'OTP sent successfully'
      };

    } catch (error) {
      console.error('SMS sending failed:', error);
      throw error;
    }
  }

  /**
   * Verify OTP code
   */
  async verifyOTP(phoneNumber, otp, otpId = null) {
    try {
      let query = `
        SELECT * FROM phone_otp_verifications 
        WHERE phone = $1 AND otp = $2 AND expires_at > NOW() AND verified = false
      `;
      let params = [phoneNumber, otp];

      if (otpId) {
        query += ' AND otp_id = $3';
        params.push(otpId);
      }

      query += ' ORDER BY created_at DESC LIMIT 1';

      const result = await database.query(query, params);

      if (result.rows.length === 0) {
        // Increment attempts for all non-expired OTPs
        await database.query(`
          UPDATE phone_otp_verifications 
          SET attempts = attempts + 1 
          WHERE phone = $1 AND expires_at > NOW() AND verified = false
        `, [phoneNumber]);
        
        throw new Error('Invalid or expired OTP');
      }

      const otpRecord = result.rows[0];

      // Check attempt limit
      if (otpRecord.attempts >= otpRecord.max_attempts) {
        throw new Error('Maximum OTP attempts exceeded');
      }

      // Mark OTP as verified
      await database.query(`
        UPDATE phone_otp_verifications 
        SET verified = true, verified_at = NOW() 
        WHERE id = $1
      `, [otpRecord.id]);

      console.log(`✅ OTP verified for ${phoneNumber}`);

      return {
        success: true,
        verified: true,
        message: 'OTP verified successfully',
        provider: otpRecord.provider_used || 'unknown'
      };

    } catch (error) {
      console.error('OTP verification failed:', error);
      throw error;
    }
  }

  /**
   * Generate 6-digit OTP
   */
  generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  /**
   * Generate unique OTP ID
   */
  generateOTPId() {
    return `otp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Check rate limiting
   */
  async checkRateLimit(phoneNumber) {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    
    const result = await database.query(`
      SELECT COUNT(*) as count 
      FROM phone_otp_verifications 
      WHERE phone = $1 AND created_at > $2
    `, [phoneNumber, oneHourAgo]);

    const count = parseInt(result.rows[0].count);
    
    // Increased limit for development and testing (was 3, now 10)
    if (count >= 10) {
      throw new Error('Too many OTP requests. Please try again later.');
    }
  }

  /**
   * Update cost tracking
   */
  async updateCostTracking(countryCode, provider, cost) {
    try {
      const currentMonth = new Date().getMonth() + 1;
      const currentYear = new Date().getFullYear();

      await database.query(`
        INSERT INTO sms_analytics 
        (country_code, provider, cost, success, month, year, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, NOW())
      `, [countryCode, provider, cost, true, currentMonth, currentYear]);

      // Update monthly totals in sms_configurations
      await database.query(`
        UPDATE sms_configurations 
        SET 
          total_sms_sent = COALESCE(total_sms_sent, 0) + 1,
          total_cost = COALESCE(total_cost, 0) + $2,
          updated_at = NOW()
        WHERE country_code = $1
      `, [countryCode, cost]);

    } catch (error) {
      console.error('Error updating cost tracking:', error);
    }
  }

  /**
   * Format provider configuration for the specific provider
   */
  formatProviderConfig(config) {
    // The config.config field contains the provider-specific configuration
    const providerConfig = config.config;
    
    switch (config.provider) {
      case 'hutch_mobile':
        return {
          hutchMobileConfig: providerConfig
        };
      case 'twilio':
        return {
          twilioConfig: providerConfig
        };
      case 'aws':
        return {
          awsConfig: providerConfig
        };
      case 'vonage':
        return {
          vonageConfig: providerConfig
        };
      case 'local':
        return {
          localConfig: providerConfig
        };
      default:
        throw new Error(`Unknown provider: ${config.provider}`);
    }
  }

  /**
   * Test SMS provider
   */
  async testProvider(countryCode, provider, testNumber) {
    try {
      const config = await this.getSMSConfig(countryCode);
      const Provider = this.providers[provider];
      
      if (!Provider) {
        throw new Error(`Unsupported provider: ${provider}`);
      }

      const providerInstance = new Provider(this.formatProviderConfig(config));
      const testMessage = `Test SMS from Request Marketplace - ${new Date().toISOString()}`;
      
      const result = await providerInstance.sendSMS(testNumber, testMessage);
      
      return {
        success: true,
        provider,
        messageId: result.messageId,
        cost: result.cost,
        timestamp: new Date()
      };

    } catch (error) {
      return {
        success: false,
        provider,
        error: error.message,
        timestamp: new Date()
      };
    }
  }
}

/**
 * 📞 Twilio Provider
 */
class TwilioProvider {
  constructor(config) {
    const twilioConfig = config.twilioConfig;
    if (!twilioConfig) {
      throw new Error('Twilio configuration not found');
    }
    
    this.client = twilio(twilioConfig.accountSid, twilioConfig.authToken);
    this.fromNumber = twilioConfig.fromNumber;
  }

  async sendSMS(to, message) {
    try {
      const result = await this.client.messages.create({
        body: message,
        from: this.fromNumber,
        to: to
      });

      return {
        success: true,
        messageId: result.sid,
        cost: 0.0075, // Estimated cost
        provider: 'twilio'
      };
    } catch (error) {
      throw new Error(`Twilio SMS failed: ${error.message}`);
    }
  }
}

/**
 * ☁️ AWS SNS Provider
 */
class AWSSNSProvider {
  constructor(config) {
    const awsConfig = config.awsConfig;
    if (!awsConfig) {
      throw new Error('AWS SNS configuration not found');
    }

    this.sns = new SNSClient({
      region: awsConfig.region,
      credentials: awsConfig.accessKeyId && awsConfig.secretAccessKey ? {
        accessKeyId: awsConfig.accessKeyId,
        secretAccessKey: awsConfig.secretAccessKey,
      } : undefined,
    });
  }

  async sendSMS(to, message) {
    try {
      const params = {
        Message: message,
        PhoneNumber: to,
        MessageAttributes: {
          'AWS.SNS.SMS.SMSType': {
            DataType: 'String',
            StringValue: 'Transactional'
          }
        }
      };

      const result = await this.sns.send(new PublishCommand(params));

      return {
        success: true,
        messageId: result.MessageId,
        cost: 0.0075, // Estimated cost
        provider: 'aws'
      };
    } catch (error) {
      throw new Error(`AWS SNS failed: ${error.message}`);
    }
  }
}

/**
 * 📞 Vonage Provider
 */
class VonageProvider {
  constructor(config) {
    const vonageConfig = config.vonageConfig;
    if (!vonageConfig) {
      throw new Error('Vonage configuration not found');
    }

    this.apiKey = vonageConfig.apiKey;
    this.apiSecret = vonageConfig.apiSecret;
    this.brandName = vonageConfig.brandName || 'RequestApp';
  }

  async sendSMS(to, message) {
    try {
      const response = await axios.post('https://rest.nexmo.com/sms/json', {
        api_key: this.apiKey,
        api_secret: this.apiSecret,
        to: to.replace('+', ''),
        from: this.brandName,
        text: message
      });

      if (response.data.messages[0].status === '0') {
        return {
          success: true,
          messageId: response.data.messages[0]['message-id'],
          cost: 0.005, // Estimated cost
          provider: 'vonage'
        };
      } else {
        throw new Error(response.data.messages[0]['error-text']);
      }
    } catch (error) {
      throw new Error(`Vonage SMS failed: ${error.message}`);
    }
  }
}

/**
 * 🏠 Local Provider
 */
class LocalProvider {
  constructor(config) {
    const localConfig = config.localConfig;
    if (!localConfig) {
      throw new Error('Local provider configuration not found');
    }

    this.endpoint = localConfig.endpoint;
    this.apiKey = localConfig.apiKey;
    this.method = localConfig.method || 'POST';
  }

  async sendSMS(to, message) {
    try {
      const response = await axios({
        method: this.method,
        url: this.endpoint,
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        },
        data: {
          to: to,
          message: message,
          from: 'RequestApp'
        }
      });

      return {
        success: true,
        messageId: response.data.messageId || Date.now().toString(),
        cost: 0.003, // Estimated cost
        provider: 'local'
      };
    } catch (error) {
      throw new Error(`Local provider SMS failed: ${error.message}`);
    }
  }
}

/**
 * 🇱🇰 Hutch Mobile Provider (Sri Lanka)
 * Uses Hutch BSMS API with authentication flow
 */
class HutchMobileProvider {
  constructor(config) {
    const hutchConfig = config.hutchMobileConfig;
    if (!hutchConfig) {
      throw new Error('Hutch Mobile provider configuration not found');
    }

    this.apiBaseUrl = 'https://bsms.hutch.lk/api';
    this.username = hutchConfig.username;
    this.password = hutchConfig.password;
    this.senderId = hutchConfig.senderId || 'ALPHABET';
    this.messageType = hutchConfig.messageType || 'text';
    this.authToken = null; // Will store authentication token

    if (!this.username || !this.password) {
      throw new Error('Hutch Mobile username and password are required');
    }
  }

  /**
   * Authenticate with Hutch API and get access token
   */
  async authenticate() {
    try {
      console.log(`🔐 Authenticating with Hutch API for user: ${this.username}`);
      
      const loginResponse = await axios.post(`${this.apiBaseUrl}/login`, {
        email: this.username,
        password: this.password
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 15000
      });

      console.log('🔐 Hutch Login Response Status:', loginResponse.status);
      console.log('🔐 Hutch Login Response:', loginResponse.data);

      if (loginResponse.data && loginResponse.data.access_token) {
        this.authToken = loginResponse.data.access_token;
        console.log('✅ Hutch authentication successful');
        return this.authToken;
      } else {
        throw new Error('Authentication failed - no access token received');
      }
    } catch (error) {
      console.error('❌ Hutch Authentication Error:', error.response?.data || error.message);
      throw new Error(`Hutch authentication failed: ${error.response?.data?.message || error.message}`);
    }
  }

  async sendSMS(to, message) {
    try {
      // Ensure we have a valid auth token
      if (!this.authToken) {
        await this.authenticate();
      }

      // Format phone number for Hutch Mobile (remove + and ensure country code)
      let cleanPhone = to.replace(/[^\d+]/g, '');
      if (cleanPhone.startsWith('+94')) {
        cleanPhone = cleanPhone.substring(3);
      } else if (cleanPhone.startsWith('94')) {
        cleanPhone = cleanPhone.substring(2);
      }
      if (cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1);
      }
      
      console.log(`📱 Sending SMS via Hutch API to: ${cleanPhone}`);

      // Prepare SMS data
      const smsData = {
        recipient: cleanPhone,
        message: message,
        sender_id: this.senderId,
        message_type: this.messageType
      };

      const response = await axios.post(`${this.apiBaseUrl}/sms/send`, smsData, {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': `Bearer ${this.authToken}`
        },
        timeout: 15000
      });

      console.log('📱 Hutch SMS API Response Status:', response.status);
      console.log('📱 Hutch SMS API Response:', response.data);

      // Handle successful response
      if (response.status === 200 || response.status === 201) {
        return {
          success: true,
          messageId: response.data.message_id || response.data.id || `hutch_${Date.now()}`,
          cost: 0.012, // Estimated cost for Sri Lanka
          provider: 'hutch_mobile',
          response: response.data
        };
      } else {
        throw new Error(response.data?.message || response.data?.error || 'SMS sending failed');
      }
    } catch (error) {
      console.error('❌ Hutch Mobile SMS Error:', error.response?.data || error.message);
      
      // If auth error, try to re-authenticate once
      if (error.response?.status === 401 && this.authToken) {
        console.log('🔄 Auth token expired, trying to re-authenticate...');
        this.authToken = null;
        try {
          await this.authenticate();
          // Retry SMS sending after re-authentication
          return await this.sendSMS(to, message);
        } catch (retryError) {
          throw new Error(`Hutch SMS failed after re-auth: ${retryError.message}`);
        }
      }
      
      throw new Error(`Hutch Mobile SMS failed: ${error.response?.data?.message || error.message}`);
    }
  }
}

module.exports = new SMSService();
