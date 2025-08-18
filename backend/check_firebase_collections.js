require('dotenv').config();
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
let serviceAccount;
try {
  console.log('Loading Firebase service account...');
  if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    console.log('Using service account from environment variable');
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
  } else if (fs.existsSync('./firebase-service-account.json')) {
    console.log('Using firebase-service-account.json');
    serviceAccount = require('./firebase-service-account.json');
  } else if (fs.existsSync('./serviceAccount.json')) {
    console.log('Using serviceAccount.json');
    serviceAccount = require('./serviceAccount.json');
  } else if (fs.existsSync('./request-marketplace-62dc9dd4835f.json')) {
    console.log('Using request-marketplace-62dc9dd4835f.json');
    serviceAccount = require('./request-marketplace-62dc9dd4835f.json');
  } else {
    console.error('Firebase service account key not found!');
    console.error('Please either:');
    console.error('1. Set FIREBASE_SERVICE_ACCOUNT_KEY environment variable with the JSON content');
    console.error('2. Place firebase-service-account.json file in the project root');
    process.exit(1);
  }
  console.log('Service account loaded for project:', serviceAccount.project_id);
} catch (error) {
  console.error('Error loading Firebase service account:', error.message);
  process.exit(1);
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DATABASE_URL
  });
  console.log('Firebase Admin initialized');
}

const db = admin.firestore();

async function listCollections() {
  try {
    console.log('🔍 Checking Firebase collections...');
    
    const collections = [
      'categories',
      'subcategories', 
      'brands',
      'vehicle_types',
      'subscription_plans',
      'master_products',
      'variable_types',
      'module_management'
    ];

    for (const collectionName of collections) {
      try {
        console.log(`\nChecking collection: ${collectionName}`);
        const snapshot = await db.collection(collectionName).limit(3).get();
        const count = snapshot.size;
        console.log(`📁 ${collectionName}: ${count > 0 ? 'EXISTS' : 'EMPTY'} (sample size: ${count})`);
        
        if (count > 0) {
          snapshot.docs.forEach((doc, index) => {
            console.log(`   Sample ${index + 1} ID: ${doc.id}`);
            const data = doc.data();
            const fieldNames = Object.keys(data);
            console.log(`   Sample ${index + 1} fields: ${fieldNames.slice(0, 5).join(', ')}${fieldNames.length > 5 ? '...' : ''}`);
          });
        }
      } catch (error) {
        console.log(`📁 ${collectionName}: ERROR - ${error.message}`);
      }
    }

    console.log('\n✅ Collection check completed');
  } catch (error) {
    console.error('❌ Error checking collections:', error.message);
  }
  
  process.exit(0);
}

listCollections();
