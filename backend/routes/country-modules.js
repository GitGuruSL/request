const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');

// GET /api/country-modules/:countryCode
router.get('/:countryCode', async (req, res) => {
  try {
    const { countryCode } = req.params;
    const row = await db.queryOne('SELECT * FROM country_modules WHERE country_code = $1', [countryCode.toUpperCase()]);
    if (!row) return res.status(404).json({ success: false, message: 'No module configuration found' });
    res.json({ success: true, ...row });
  } catch (e) {
    console.error('Fetch country modules error', e);
    res.status(500).json({ success: false, message: 'Error fetching country modules' });
  }
});

// PUT /api/country-modules/:countryCode (upsert)
router.put('/:countryCode', auth.authMiddleware(), auth.roleMiddleware(['super_admin','country_admin']), async (req, res) => {
  try {
    const { countryCode } = req.params;
    const { modules = {}, coreDependencies = {}, version = '1.0.0' } = req.body;

    // If country_admin, enforce only their own country
    if (req.user.role === 'country_admin' && req.user.country_code && req.user.country_code.toUpperCase() !== countryCode.toUpperCase()) {
      return res.status(403).json({ success:false, message:'Cannot modify other countries' });
    }

    const upsert = await db.queryOne(`
      INSERT INTO country_modules (country_code, modules, core_dependencies, version)
      VALUES ($1,$2::jsonb,$3::jsonb,$4)
      ON CONFLICT (country_code) DO UPDATE
        SET modules = EXCLUDED.modules,
            core_dependencies = EXCLUDED.core_dependencies,
            version = EXCLUDED.version,
            updated_at = NOW()
      RETURNING *
    `, [countryCode.toUpperCase(), JSON.stringify(modules), JSON.stringify(coreDependencies), version]);
    res.json({ success:true, message:'Configuration saved', data: upsert });
  } catch (e) {
    console.error('Upsert country modules error', e);
    res.status(500).json({ success:false, message:'Error saving configuration' });
  }
});

module.exports = router;
