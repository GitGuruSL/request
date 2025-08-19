const express = require('express');
const router = express.Router();
const db = require('../services/database');
const auth = require('../services/auth');
const smsService = require('../services/sms');

async function ensureProviderTable(){
  await smsService.ensureTable();
}

// List provider configs for a country
router.get('/config/:countryCode', auth.authMiddleware(), auth.roleMiddleware(['super_admin','country_admin']), async (req,res)=>{
  try {
    const { countryCode } = req.params;
    await ensureProviderTable();
    const rows = await db.query('SELECT provider, config, is_active FROM sms_provider_configs WHERE country_code = $1 ORDER BY updated_at DESC', [countryCode.toUpperCase()]);
    res.json({ success:true, data: rows.rows });
  } catch(e){
    console.error('[sms][get-config] error', e);
    res.status(500).json({ success:false, message:'Failed to fetch config' });
  }
});

// Upsert a provider config
router.put('/config/:countryCode/:provider', auth.authMiddleware(), auth.roleMiddleware(['super_admin','country_admin']), async (req,res)=>{
  try {
    const { countryCode, provider } = req.params;
  const { config = {}, is_active = true, exclusive = true } = req.body || {};
    if (!smsService.supportedProviders.has(provider)) {
      return res.status(400).json({ success:false, message:'Unsupported provider' });
    }
    await ensureProviderTable();
    const upsert = await db.queryOne(`
      INSERT INTO sms_provider_configs (country_code, provider, config, is_active)
      VALUES ($1,$2,$3::jsonb,$4)
      ON CONFLICT (country_code, provider) DO UPDATE SET config = EXCLUDED.config, is_active = EXCLUDED.is_active, updated_at = NOW()
      RETURNING country_code, provider, config, is_active, updated_at
    `, [countryCode.toUpperCase(), provider, JSON.stringify(config), is_active]);
    if (exclusive && is_active) {
      // Deactivate other providers for this country
      await db.query('UPDATE sms_provider_configs SET is_active = FALSE, updated_at = NOW() WHERE country_code=$1 AND provider <> $2', [countryCode.toUpperCase(), provider]);
    }
    res.json({ success:true, message:'Configuration saved', data: upsert });
  } catch(e){
    console.error('[sms][upsert-config] error', e);
    res.status(500).json({ success:false, message:'Failed to save config' });
  }
});

// Send OTP
router.post('/send-otp', async (req,res)=>{
  try { 
    const { phone, country_code } = req.body || {}; 
    if (!phone) return res.status(400).json({ success:false, message:'phone required'});
    const otp = Math.floor(100000 + Math.random()*900000).toString();
    await db.query(`CREATE TABLE IF NOT EXISTS otp_codes (id SERIAL PRIMARY KEY, phone TEXT, country_code TEXT, code TEXT, created_at TIMESTAMPTZ DEFAULT NOW())`);
    await db.query('INSERT INTO otp_codes (phone, country_code, code) VALUES ($1,$2,$3)', [phone, (country_code||'').toUpperCase() || null, otp]);
    const result = await smsService.sendOTP({ phone, otp, countryCode: country_code });
    res.json({ success:true, message:'OTP sent', provider: result.provider });
  } catch(e){
    console.error('[sms][send-otp] error', e);
    res.status(500).json({ success:false, message:'Failed to send OTP' });
  }
});

// Verify OTP
router.post('/verify-otp', async (req,res)=>{
  try { 
    const { phone, code } = req.body || {}; 
    if (!phone || !code) return res.status(400).json({ success:false, message:'phone & code required'});
    await db.query(`CREATE TABLE IF NOT EXISTS otp_codes (id SERIAL PRIMARY KEY, phone TEXT, country_code TEXT, code TEXT, created_at TIMESTAMPTZ DEFAULT NOW())`);
    const row = await db.queryOne('SELECT * FROM otp_codes WHERE phone=$1 ORDER BY created_at DESC LIMIT 1', [phone]);
    if (!row) return res.status(400).json({ success:false, message:'No OTP sent' });
    if (Date.now() - new Date(row.created_at).getTime() > 10*60*1000) return res.status(400).json({ success:false, message:'OTP expired'});
    if (row.code !== code) return res.status(400).json({ success:false, message:'Invalid code'});
    res.json({ success:true, message:'OTP verified' });
  } catch(e){
    console.error('[sms][verify-otp] error', e);
    res.status(500).json({ success:false, message:'Failed to verify OTP' });
  }
});

// Basic statistics per country
router.get('/statistics/:countryCode', auth.authMiddleware(), auth.roleMiddleware(['super_admin','country_admin']), async (req,res)=>{
  try {
    const { countryCode } = req.params;
    await db.query(`CREATE TABLE IF NOT EXISTS otp_codes (id SERIAL PRIMARY KEY, phone TEXT, country_code TEXT, code TEXT, created_at TIMESTAMPTZ DEFAULT NOW())`);
    const totalRow = await db.queryOne('SELECT COUNT(*)::int AS total FROM otp_codes WHERE country_code = $1', [countryCode.toUpperCase()]);
    const totalSent = totalRow.total || 0;
    const { provider } = await smsService.getActiveProvider(countryCode.toUpperCase());
    const providerUnitCost = (p=>({ twilio:0.0075, aws_sns:0.0075, vonage:0.0072, local_http:0.003, dev:0 })(p) || 0.0075)(provider);
    const firebaseAvg = 0.015; // assumed
    const costSavings = Math.max(0, (firebaseAvg - providerUnitCost) * totalSent).toFixed(2);
    res.json({ success:true, data:{ countryCode: countryCode.toUpperCase(), totalSent, successRate: 100, costSavings: Number(costSavings), provider, lastMonth:{ sent: totalSent, cost: Number((totalSent*providerUnitCost).toFixed(2)) } } });
  } catch(e){
    console.error('[sms][statistics] error', e);
    res.status(500).json({ success:false, message:'Failed to load statistics' });
  }
});

module.exports = router;
