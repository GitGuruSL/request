require('dotenv').config({
  path: process.env.NODE_ENV === 'production' ? '.env.prod' : '.env.rds'
});

const express = require('express');
const request = require('supertest');
const countryProductsRouter = require('./routes/country-products');

// Create test app
const app = express();
app.use('/api/country-products', countryProductsRouter);

async function testCountryProductsAPI() {
  console.log('Testing Country Products API...');
  
  try {
    const response = await request(app)
      .get('/api/country-products?country=LK')
      .expect(200);
    
    console.log('API Response Status:', response.status);
    console.log('API Response Data Length:', response.body.data?.length || 0);
    console.log('API Response Success:', response.body.success);
    
    if (response.body.data && response.body.data.length > 0) {
      console.log('\nFirst few products:');
      response.body.data.slice(0, 3).forEach((product, index) => {
        console.log(`${index + 1}. ${product.name}`);
        console.log(`   ID: ${product.id}`);
        console.log(`   Country Enabled: ${product.countryEnabled}`);
        console.log(`   Base Unit: ${product.baseUnit}`);
        console.log(`   Is Active: ${product.isActive}`);
        console.log('');
      });
      
      console.log(`Total products returned: ${response.body.data.length}`);
    } else {
      console.log('No products returned from API');
    }
    
  } catch (error) {
    console.error('Error testing API:', error.message);
  }
}

testCountryProductsAPI();
