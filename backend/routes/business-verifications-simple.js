const express = require('express');
const router = express.Router();

console.log('🏢 Simple business verification routes loaded');

// Test endpoint
router.get('/test', (req, res) => {
  res.json({
    success: true,
    message: 'Simple business verification routes are working!',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
