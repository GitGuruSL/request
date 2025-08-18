// Test categories API endpoint from Flutter perspective
// This simulates what the Flutter app would do

const express = require('express');
const router = express.Router();

// Test endpoint to simulate Flutter API calls
router.get('/test-categories', async (req, res) => {
  try {
    const { type } = req.query;
    console.log(`🧪 Testing categories API for type: ${type}`);
    
    const apiUrl = `http://localhost:3001/api/categories${type ? `?type=${type}` : ''}`;
    console.log(`📡 Calling: ${apiUrl}`);
    
    // Here we would normally make the API call
    // For now, just return success to confirm the endpoint structure
    res.json({
      success: true,
      message: `Categories API test for type: ${type || 'all'}`,
      apiUrl: apiUrl,
      expectedFields: [
        'id',
        'name', 
        'type',
        'is_active',
        'created_at',
        'updated_at'
      ]
    });
    
  } catch (error) {
    console.error('Test error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
