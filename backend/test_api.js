const https = require('http');

function testCheckUserAPI() {
  const postData = JSON.stringify({
    emailOrPhone: 'rimaz.m.flyil@gmail.com'
  });

  const options = {
    hostname: 'localhost',
    port: 3001,
    path: '/api/auth/check-user-exists',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  console.log('🧪 Testing API endpoint: POST http://localhost:3001/api/auth/check-user-exists');
  console.log('📤 Request data:', postData);

  const req = https.request(options, (res) => {
    console.log(`📊 Response status: ${res.statusCode}`);
    console.log(`📊 Response headers:`, res.headers);

    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });

    res.on('end', () => {
      console.log('📥 Response body:', data);
      try {
        const parsed = JSON.parse(data);
        console.log('📋 Parsed response:', parsed);
        console.log('✅ User exists?', parsed.exists);
      } catch (e) {
        console.log('❌ Failed to parse JSON:', e.message);
      }
    });
  });

  req.on('error', (e) => {
    console.error('❌ Request error:', e.message);
  });

  req.write(postData);
  req.end();
}

testCheckUserAPI();
