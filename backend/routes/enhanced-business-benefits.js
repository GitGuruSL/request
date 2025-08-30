const express = require('express');
const router = express.Router();
const dbService = require('../services/database');

// Helper to resolve a country identifier (numeric id or code) to numeric id
async function resolveCountryId(client, countryIdOrCode) {
  if (!countryIdOrCode) return null;
  const asNumber = parseInt(countryIdOrCode, 10);
  if (!Number.isNaN(asNumber)) return asNumber;
  const { rows } = await client.query(
    `SELECT id FROM countries WHERE LOWER(code) = LOWER($1) LIMIT 1`,
    [String(countryIdOrCode)]
  );
  return rows[0]?.id || null;
}

/**
 * GET /api/enhanced-business-benefits/:countryId
 * Get all benefit plans for all business types in a country
 */
router.get('/:countryId', async (req, res) => {
  try {
    const { countryId } = req.params;
    const client = await dbService.pool.connect();
    
    try {
      const resolvedId = await resolveCountryId(client, countryId);
      if (!resolvedId) {
        return res.status(400).json({ error: 'Valid country ID or code is required' });
      }

      // Get all business types
      const businessTypesResult = await client.query(
        'SELECT id, name FROM business_types ORDER BY name'
      );

      const benefits = {};
      
      for (const businessType of businessTypesResult.rows) {
        // Get plans for this business type (fallback to default if no custom plans)
        const plansResult = await client.query(
          `SELECT * FROM enhanced_business_benefits 
           WHERE country_id = $1 AND business_type_id = $2 
           ORDER BY plan_code`,
          [resolvedId, businessType.id]
        );

        // If no custom plans, return default structure
        const plans = plansResult.rows.length > 0 ? plansResult.rows.map(plan => ({
          planId: plan.id,
          planCode: plan.plan_code,
          planName: plan.plan_name,
          pricingModel: plan.pricing_model,
          features: plan.features || {},
          pricing: plan.pricing || {},
          isActive: plan.is_active
        })) : [];

        benefits[businessType.name] = {
          businessTypeId: businessType.id,
          businessTypeName: businessType.name,
          plans: plans
        };
      }
            planName: plan.plan_name,
            planDescription: plan.plan_description,
            planType: plan.plan_type,
            isActive: plan.is_active,
            sortOrder: plan.sort_order,
            config: plan.config_data,
            allowedResponseTypes: plan.allowed_response_types
          }))
        };
      }

      res.json({
        success: true,
        countryId: resolvedId,
        businessTypeBenefits: benefits,
        timestamp: new Date().toISOString()
      });

    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Error fetching enhanced business benefits:', error);
    res.status(500).json({
      error: 'Failed to fetch business benefits',
      details: error.message
    });
  }
});

/**
 * GET /api/enhanced-business-benefits/:countryId/:businessTypeId
 * Get benefit plans for a specific business type
 */
router.get('/:countryId/:businessTypeId', async (req, res) => {
  try {
    const { countryId, businessTypeId } = req.params;
    const client = await dbService.pool.connect();
    
    try {
      const resolvedId = await resolveCountryId(client, countryId);
      if (!resolvedId) {
        return res.status(400).json({ error: 'Valid country ID or code is required' });
      }

      const plansResult = await client.query(
        'SELECT * FROM get_business_type_benefit_plans($1, $2)',
        [resolvedId, parseInt(businessTypeId)]
      );

      const businessTypeResult = await client.query(
        'SELECT name FROM business_types WHERE id = $1',
        [parseInt(businessTypeId)]
      );

      if (businessTypeResult.rows.length === 0) {
        return res.status(404).json({ error: 'Business type not found' });
      }

      res.json({
        success: true,
        countryId: resolvedId,
        businessTypeId: parseInt(businessTypeId),
        businessTypeName: businessTypeResult.rows[0].name,
        plans: plansResult.rows.map(plan => ({
          planId: plan.plan_id,
          planCode: plan.plan_code,
          planName: plan.plan_name,
          planDescription: plan.plan_description,
          planType: plan.plan_type,
          isActive: plan.is_active,
          sortOrder: plan.sort_order,
          config: plan.config_data,
          allowedResponseTypes: plan.allowed_response_types
        })),
        timestamp: new Date().toISOString()
      });

    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Error fetching business type benefits:', error);
    res.status(500).json({
      error: 'Failed to fetch business type benefits',
      details: error.message
    });
  }
});

/**
 * POST /api/enhanced-business-benefits/:countryId/:businessTypeId/plans
 * Create a new benefit plan for a business type
 */
router.post('/:countryId/:businessTypeId/plans', async (req, res) => {
  try {
    const { countryId, businessTypeId } = req.params;
    const {
      planCode,
      planName,
      planDescription,
      planType,
      config,
      allowedResponseTypes = []
    } = req.body;

    const client = await dbService.pool.connect();
    
    try {
      const resolvedId = await resolveCountryId(client, countryId);
      if (!resolvedId) {
        return res.status(400).json({ error: 'Valid country ID or code is required' });
      }

      // TODO: Add admin authentication middleware
      const adminUserId = req.user?.id || null;

      await client.query('BEGIN');

      // Create the plan
      const planResult = await client.query(`
        INSERT INTO business_type_benefit_plans 
        (country_id, business_type_id, plan_code, plan_name, plan_description, plan_type, created_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id
      `, [resolvedId, parseInt(businessTypeId), planCode, planName, planDescription, planType, adminUserId]);

      const planId = planResult.rows[0].id;

      // Add configuration data
      if (config && typeof config === 'object') {
        for (const [configKey, configData] of Object.entries(config)) {
          await client.query(`
            INSERT INTO business_type_benefit_configs (plan_id, config_key, config_data)
            VALUES ($1, $2, $3)
          `, [planId, configKey, JSON.stringify(configData)]);
        }
      }

      // Add allowed response types
      if (allowedResponseTypes.length > 0) {
        for (const responseTypeId of allowedResponseTypes) {
          await client.query(`
            INSERT INTO business_type_allowed_responses (plan_id, can_respond_to_business_type_id)
            VALUES ($1, $2)
          `, [planId, parseInt(responseTypeId)]);
        }
      }

      await client.query('COMMIT');

      res.status(201).json({
        success: true,
        message: 'Benefit plan created successfully',
        planId: planId,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Error creating benefit plan:', error);
    res.status(500).json({
      error: 'Failed to create benefit plan',
      details: error.message
    });
  }
});

/**
 * PUT /api/enhanced-business-benefits/plans/:planId/config
 * Update configuration for a specific plan
 */
router.put('/plans/:planId/config', async (req, res) => {
  try {
    const { planId } = req.params;
    const { configKey, configData } = req.body;

    if (!configKey || !configData) {
      return res.status(400).json({ error: 'configKey and configData are required' });
    }

    const client = await dbService.pool.connect();
    
    try {
      // TODO: Add admin authentication middleware
      const adminUserId = req.user?.id || null;

      const result = await client.query(
        'SELECT update_benefit_plan_config($1, $2, $3, $4)',
        [parseInt(planId), configKey, JSON.stringify(configData), adminUserId]
      );

      const updateResult = result.rows[0].update_benefit_plan_config;

      if (updateResult.success) {
        res.json({
          success: true,
          message: 'Configuration updated successfully',
          timestamp: new Date().toISOString()
        });
      } else {
        res.status(400).json({
          success: false,
          error: updateResult.message || 'Failed to update configuration'
        });
      }

    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Error updating plan configuration:', error);
    res.status(500).json({
      error: 'Failed to update plan configuration',
      details: error.message
    });
  }
});

/**
 * PUT /api/enhanced-business-benefits/plans/:planId/allowed-responses
 * Update allowed response types for a plan
 */
router.put('/plans/:planId/allowed-responses', async (req, res) => {
  try {
    const { planId } = req.params;
    const { allowedResponseTypes = [] } = req.body;

    const client = await dbService.pool.connect();
    
    try {
      await client.query('BEGIN');

      // Clear existing allowed response types
      await client.query(
        'DELETE FROM business_type_allowed_responses WHERE plan_id = $1',
        [parseInt(planId)]
      );

      // Add new allowed response types
      for (const responseTypeId of allowedResponseTypes) {
        await client.query(`
          INSERT INTO business_type_allowed_responses (plan_id, can_respond_to_business_type_id)
          VALUES ($1, $2)
        `, [parseInt(planId), parseInt(responseTypeId)]);
      }

      await client.query('COMMIT');

      res.json({
        success: true,
        message: 'Allowed response types updated successfully',
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Error updating allowed response types:', error);
    res.status(500).json({
      error: 'Failed to update allowed response types',
      details: error.message
    });
  }
});

/**
 * GET /api/enhanced-business-benefits/admin/:countryId
 * Get all benefit plans for admin management
 */
router.get('/admin/:countryId', async (req, res) => {
  try {
    const { countryId } = req.params;
    const client = await dbService.pool.connect();
    
    try {
      const resolvedId = await resolveCountryId(client, countryId);
      if (!resolvedId) {
        return res.status(400).json({ error: 'Valid country ID or code is required' });
      }

      // TODO: Add admin authentication middleware

      const result = await client.query(`
        SELECT 
          bp.*,
          bt.name as business_type_name,
          c.name as country_name,
          COALESCE(
            jsonb_object_agg(bc.config_key, bc.config_data) FILTER (WHERE bc.config_key IS NOT NULL),
            '{}'::jsonb
          ) as config_data,
          COALESCE(
            array_agg(DISTINCT bar.can_respond_to_business_type_id) FILTER (WHERE bar.can_respond_to_business_type_id IS NOT NULL),
            ARRAY[]::integer[]
          ) as allowed_response_types
        FROM business_type_benefit_plans bp
        JOIN business_types bt ON bp.business_type_id = bt.id
        JOIN countries c ON bp.country_id = c.id
        LEFT JOIN business_type_benefit_configs bc ON bp.id = bc.plan_id
        LEFT JOIN business_type_allowed_responses bar ON bp.id = bar.plan_id AND bar.is_active = true
        WHERE bp.country_id = $1
        GROUP BY bp.id, bt.name, c.name
        ORDER BY bt.name, bp.sort_order, bp.plan_name
      `, [resolvedId]);

      res.json({
        success: true,
        countryId: resolvedId,
        plans: result.rows,
        timestamp: new Date().toISOString()
      });

    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Error fetching admin benefit plans:', error);
    res.status(500).json({
      error: 'Failed to fetch admin benefit plans',
      details: error.message
    });
  }
});

module.exports = router;
