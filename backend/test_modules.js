const express = require('express');
const app = express();
app.use(express.json());

// Test the modules route
const modulesRoute = require('./routes/modules');
app.use('/api/modules', modulesRoute);

const port = 3001;
app.listen(port, () => {
  console.log('Test server running on port', port);
  console.log('Test the following URLs:');
  console.log('GET http://localhost:3001/api/modules/enabled?country=LK');
  console.log('GET http://localhost:3001/api/modules/all');
  console.log('GET http://localhost:3001/api/modules/check/ride_sharing?country=LK');
  
  // Keep the server running
  console.log('Press Ctrl+C to stop the server');
});
