const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.post('/api/requests', (req, res) => {
  console.log('=== REQUEST CREATE DATA ===');
  console.log('Headers:', req.headers);
  console.log('Body:', JSON.stringify(req.body, null, 2));
  console.log('Location fields:');
  console.log('- location_address:', req.body.location_address);
  console.log('- location_latitude:', req.body.location_latitude); 
  console.log('- location_longitude:', req.body.location_longitude);
  console.log('============================');
  
  res.json({ success: true, message: 'Test endpoint - data logged' });
});

app.listen(3002, () => {
  console.log('Test server listening on port 3002');
  console.log('Ready to receive requests...');
});
