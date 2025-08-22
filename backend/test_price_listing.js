const http = require('http');

// Test data with both multer-style files and direct image URLs
const testPayload = {
  masterProductId: '13ef0173-0b67-45d8-8046-524dcf0c06dd',
  categoryId: '732f29d3-637b-4c20-9c6d-e90f472143f7', // Electronics
  subcategoryId: null,
  title: 'Test iPhone with Images',
  description: 'Apple iPhone 15 Pro with proper category and images',
  price: 500000,
  currency: 'LKR',
  unit: 'piece',
  deliveryCharge: 0,
  images: [
    'https://s3.amazonaws.com/mybucket/price_listings/test-image-1.jpg',
    'https://s3.amazonaws.com/mybucket/price_listings/test-image-2.jpg'
  ],
  countryCode: 'LK'
};

const postData = JSON.stringify(testPayload);

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/price-listings',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjI1ZGFlMjBiLTA0MDQtNDA3YS1iMmM4LWI5OWU4N2EzMWE0YSIsImVtYWlsIjoidGVzdEB0ZXN0LmNvbSIsImlhdCI6MTcyNDMxOTEzMn0.test',
    'Content-Length': Buffer.byteLength(postData)
  }
};

console.log('Testing price listing creation with:');
console.log('- Category ID:', testPayload.categoryId);
console.log('- Images array:', testPayload.images);
console.log('- Master Product ID:', testPayload.masterProductId);

const req = http.request(options, (res) => {
  console.log('\n--- Response ---');
  console.log('Status:', res.statusCode);
  console.log('Headers:', res.headers);
  
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    console.log('Response Body:', data);
    
    if (res.statusCode === 201) {
      console.log('\n✅ Price listing created successfully!');
      // Query the database to verify the data was saved correctly
      setTimeout(() => {
        const { pool } = require('./services/database');
        pool.query('SELECT id, title, price, category_id, subcategory_id, images, created_at FROM price_listings ORDER BY created_at DESC LIMIT 1')
          .then(r => {
            console.log('\n--- Database Verification ---');
            console.log('Latest listing:', r.rows[0]);
            
            const listing = r.rows[0];
            console.log('\n--- Verification Results ---');
            console.log('✅ Category ID saved:', listing.category_id || '❌ Missing');
            console.log('✅ Images saved:', Array.isArray(listing.images) && listing.images.length > 0 ? listing.images : '❌ Missing or empty');
            console.log('✅ Title saved:', listing.title);
            console.log('✅ Price saved:', listing.price);
            
            process.exit(0);
          })
          .catch(err => {
            console.error('❌ Database verification error:', err.message);
            process.exit(1);
          });
      }, 1000);
    } else {
      console.log('❌ Price listing creation failed');
      process.exit(1);
    }
  });
});

req.on('error', (e) => {
  console.error('❌ Request error:', e.message);
  process.exit(1);
});

req.write(postData);
req.end();
