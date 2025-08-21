const express = require('express');

const app = express();
app.use(express.json());

// Test endpoint without authentication for testing ride request validation
app.post('/test-ride-request', async (req, res) => {
  try {
    const {
      title,
      description,
      category_id,
      city_id,
      location_address,
      location_latitude,
      location_longitude,
      budget,
      currency,
      deadline,
      image_urls,
      metadata
    } = req.body;

    console.log('=== RIDE REQUEST TEST ===');
    console.log('Full req.body:', JSON.stringify(req.body, null, 2));
    console.log('metadata field exists?', 'metadata' in req.body);
    console.log('metadata value:', req.body.metadata);
    console.log('=== VALIDATION TEST ===');

    // Same validation logic as the actual endpoint
    const isRideRequest = metadata && 
                          metadata.request_type === 'ride' && 
                          metadata.pickup && 
                          metadata.destination;
    
    console.log('isRideRequest:', isRideRequest);
    console.log('title:', !!title);
    console.log('description:', !!description);
    console.log('city_id:', !!city_id);
    console.log('category_id:', !!category_id);
    
    if (!title || !description || !city_id) {
      return res.status(400).json({
        success: false,
        message: 'Title, description, and city_id are required'
      });
    }
    
    // Only require category_id for non-ride requests
    if (!isRideRequest && !category_id) {
      return res.status(400).json({
        success: false,
        message: 'Category is required for non-ride requests'
      });
    }

    console.log('✅ Validation passed!');

    // Mock successful creation
    const mockRequest = {
      id: '12345678-1234-1234-1234-123456789999',
      title,
      description,
      category_id: category_id || null,
      city_id,
      location_address,
      location_latitude,
      location_longitude,
      metadata: metadata ? JSON.stringify(metadata) : null,
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    res.status(201).json({
      success: true,
      message: 'Request created successfully (TEST MODE)',
      data: mockRequest
    });

  } catch (error) {
    console.error('Error in test endpoint:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

const PORT = 3002;
app.listen(PORT, () => {
  console.log(`🧪 Test server running on port ${PORT}`);
  console.log('Use POST /test-ride-request to test ride request validation');
});

module.exports = app;
