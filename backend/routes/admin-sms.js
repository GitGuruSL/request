const express = require('express');
const router = express.Router();
const database = require('../services/database');
const smsService = require('../services/smsService');
const auth = require('../services/auth');

console.log('🔧 Admin SMS routes loaded');

/**
 * @route GET /api/admin/sms-configurations
 * @desc Get all SMS configurations
 * @access Admin only
 */
router.get('/sms-configurations', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const result = await database.query(`
      SELECT 
        id,
        country_code,
        country_name,
        active_provider,
        is_active,
        twilio_config,
        aws_config,
        vonage_config,
        local_config,
        total_sms_sent,
        total_cost,
        cost_per_sms,
        created_at,
        updated_at
      FROM sms_configurations
      ORDER BY country_name
    `);

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('Error fetching SMS configurations:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch SMS configurations'
    });
  }
});

/**
 * @route POST /api/admin/sms-configurations
 * @desc Create or update SMS configuration
 * @access Admin only
 */
router.post('/sms-configurations', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const {
      countryCode,
      activeProvider,
      twilioConfig,
      awsConfig,
      vonageConfig,
      localConfig,
      isActive
    } = req.body;

    // Validation
    if (!countryCode || !activeProvider) {
      return res.status(400).json({
        success: false,
        message: 'Country code and active provider are required'
      });
    }

    // Check if configuration exists
    const existingConfig = await database.query(
      'SELECT id FROM sms_configurations WHERE country_code = $1',
      [countryCode]
    );

    let result;
    if (existingConfig.rows.length > 0) {
      // Update existing configuration
      result = await database.query(`
        UPDATE sms_configurations SET
          active_provider = $2,
          is_active = $3,
          twilio_config = $4,
          aws_config = $5,
          vonage_config = $6,
          local_config = $7,
          updated_at = NOW()
        WHERE country_code = $1
        RETURNING *
      `, [
        countryCode,
        activeProvider,
        isActive,
        twilioConfig ? JSON.stringify(twilioConfig) : null,
        awsConfig ? JSON.stringify(awsConfig) : null,
        vonageConfig ? JSON.stringify(vonageConfig) : null,
        localConfig ? JSON.stringify(localConfig) : null
      ]);
    } else {
      // Create new configuration
      const countryName = getCountryName(countryCode);
      result = await database.query(`
        INSERT INTO sms_configurations (
          country_code, country_name, active_provider, is_active,
          twilio_config, aws_config, vonage_config, local_config,
          created_at, updated_at, created_by
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW(), $9)
        RETURNING *
      `, [
        countryCode,
        countryName,
        activeProvider,
        isActive,
        twilioConfig ? JSON.stringify(twilioConfig) : null,
        awsConfig ? JSON.stringify(awsConfig) : null,
        vonageConfig ? JSON.stringify(vonageConfig) : null,
        localConfig ? JSON.stringify(localConfig) : null,
        req.user.email
      ]);
    }

    res.json({
      success: true,
      data: result.rows[0],
      message: 'SMS configuration saved successfully'
    });

  } catch (error) {
    console.error('Error saving SMS configuration:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to save SMS configuration'
    });
  }
});

/**
 * @route POST /api/admin/test-sms-provider
 * @desc Test SMS provider configuration
 * @access Admin only
 */
router.post('/test-sms-provider', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { countryCode, provider, testNumber } = req.body;

    if (!countryCode || !provider || !testNumber) {
      return res.status(400).json({
        success: false,
        message: 'Country code, provider, and test number are required'
      });
    }

    // Validate phone number format
    const phoneRegex = /^\+[1-9]\d{1,14}$/;
    if (!phoneRegex.test(testNumber)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid phone number format'
      });
    }

    console.log(`🧪 Testing ${provider} provider for ${countryCode} with number ${testNumber}`);

    const result = await smsService.testProvider(countryCode, provider, testNumber);

    res.json({
      success: result.success,
      data: result,
      message: result.success ? 'Test SMS sent successfully' : 'Test SMS failed'
    });

  } catch (error) {
    console.error('Error testing SMS provider:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to test SMS provider'
    });
  }
});

/**
 * @route GET /api/admin/sms-analytics
 * @desc Get SMS analytics for a country
 * @access Admin only
 */
router.get('/sms-analytics', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { country = 'LK' } = req.query;
    const currentMonth = new Date().getMonth() + 1;
    const currentYear = new Date().getFullYear();

    // Get current month stats
    const currentMonthStats = await database.query(`
      SELECT 
        COUNT(*) as total_sent,
        SUM(cost) as total_cost,
        AVG(cost) as cost_per_sms,
        SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful_sms
      FROM sms_analytics 
      WHERE country_code = $1 AND month = $2 AND year = $3
    `, [country, currentMonth, currentYear]);

    // Get last month stats for comparison
    const lastMonth = currentMonth === 1 ? 12 : currentMonth - 1;
    const lastMonthYear = currentMonth === 1 ? currentYear - 1 : currentYear;
    
    const lastMonthStats = await database.query(`
      SELECT 
        COUNT(*) as total_sent,
        SUM(cost) as total_cost,
        AVG(cost) as cost_per_sms
      FROM sms_analytics 
      WHERE country_code = $1 AND month = $2 AND year = $3
    `, [country, lastMonth, lastMonthYear]);

    // Get recent activity (last 7 days)
    const recentActivity = await database.query(`
      SELECT 
        DATE(created_at) as date,
        provider,
        COUNT(*) as count,
        SUM(cost) as cost,
        ROUND(
          (SUM(CASE WHEN success THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)) * 100, 
          1
        ) as success_rate
      FROM sms_analytics 
      WHERE country_code = $1 AND created_at >= NOW() - INTERVAL '7 days'
      GROUP BY DATE(created_at), provider
      ORDER BY date DESC, provider
    `, [country]);

    // Get provider breakdown
    const providerBreakdown = await database.query(`
      SELECT 
        provider,
        COUNT(*) as total_sms,
        SUM(cost) as total_cost,
        AVG(cost) as avg_cost,
        ROUND(
          (SUM(CASE WHEN success THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)) * 100, 
          1
        ) as success_rate
      FROM sms_analytics 
      WHERE country_code = $1 AND month = $2 AND year = $3
      GROUP BY provider
      ORDER BY total_sms DESC
    `, [country, currentMonth, currentYear]);

    res.json({
      success: true,
      data: {
        countryCode: country,
        currentMonth: {
          totalSent: parseInt(currentMonthStats.rows[0].total_sent) || 0,
          totalCost: parseFloat(currentMonthStats.rows[0].total_cost) || 0,
          costPerSMS: parseFloat(currentMonthStats.rows[0].cost_per_sms) || 0,
          successfulSMS: parseInt(currentMonthStats.rows[0].successful_sms) || 0
        },
        lastMonth: {
          totalSent: parseInt(lastMonthStats.rows[0].total_sent) || 0,
          totalCost: parseFloat(lastMonthStats.rows[0].total_cost) || 0,
          costPerSMS: parseFloat(lastMonthStats.rows[0].cost_per_sms) || 0
        },
        recentActivity: recentActivity.rows,
        providerBreakdown: providerBreakdown.rows
      }
    });

  } catch (error) {
    console.error('Error fetching SMS analytics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch SMS analytics'
    });
  }
});

/**
 * @route GET /api/admin/sms-configurations/:countryCode
 * @desc Get SMS configuration for specific country
 * @access Admin only
 */
router.get('/sms-configurations/:countryCode', auth.authMiddleware(), auth.roleMiddleware(['super_admin', 'country_admin']), async (req, res) => {
  try {
    const { countryCode } = req.params;

    const result = await database.query(`
      SELECT *
      FROM sms_configurations
      WHERE country_code = $1
    `, [countryCode]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'SMS configuration not found for this country'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });

  } catch (error) {
    console.error('Error fetching SMS configuration:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch SMS configuration'
    });
  }
});

/**
 * @route DELETE /api/admin/sms-configurations/:countryCode
 * @desc Delete SMS configuration
 * @access Super Admin only
 */
router.delete('/sms-configurations/:countryCode', auth.authMiddleware(), auth.roleMiddleware(['super_admin']), async (req, res) => {
  try {
    const { countryCode } = req.params;

    await database.query(
      'DELETE FROM sms_configurations WHERE country_code = $1',
      [countryCode]
    );

    res.json({
      success: true,
      message: 'SMS configuration deleted successfully'
    });

  } catch (error) {
    console.error('Error deleting SMS configuration:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete SMS configuration'
    });
  }
});

/**
 * Helper function to get country name from code
 */
function getCountryName(countryCode) {
  const countries = {
    'LK': 'Sri Lanka',
    'IN': 'India',
    'US': 'United States',
    'UK': 'United Kingdom',
    'AE': 'United Arab Emirates'
  };
  return countries[countryCode] || countryCode;
}

module.exports = router;
