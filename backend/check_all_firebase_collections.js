require('dotenv').config();
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
let serviceAccount;
try {
  if (fs.existsSync('./serviceAccount.json')) {
    serviceAccount = require('./serviceAccount.json');
  } else {
    console.error('Firebase service account not found!');
    process.exit(1);
  }
} catch (error) {
  console.error('Error loading Firebase service account:', error.message);
  process.exit(1);
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function checkAllCollections() {
  try {
    console.log('🔍 Checking ALL Firebase collections...\n');
    
    const collections = await db.listCollections();
    
    for (const collection of collections) {
      console.log(`📁 Collection: ${collection.id}`);
      
      try {
        const snapshot = await collection.limit(3).get();
        console.log(`   Documents: ${snapshot.size}`);
        
        if (!snapshot.empty) {
          snapshot.docs.forEach((doc, index) => {
            console.log(`   Sample ${index + 1} ID: ${doc.id}`);
            const fields = Object.keys(doc.data());
            console.log(`   Sample ${index + 1} fields: ${fields.slice(0, 5).join(', ')}${fields.length > 5 ? '...' : ''}`);
          });
        }
      } catch (error) {
        console.log(`   ❌ Error reading collection: ${error.message}`);
      }
      
      console.log('');
    }
    
  } catch (error) {
    console.error('Error checking collections:', error);
  }
}

checkAllCollections();
