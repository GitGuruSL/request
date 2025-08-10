// Quick test to check business profile data in Firestore
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'request-marketplace'
  });
}

const db = admin.firestore();

async function checkBusinessProfile() {
  try {
    console.log('🔍 Checking business profile for user G68WKHAnd8WuIlYlx8iHBO6urDy2...');
    
    const userDoc = await db.collection('users').doc('G68WKHAnd8WuIlYlx8iHBO6urDy2').get();
    
    if (!userDoc.exists) {
      console.log('❌ User document not found');
      return;
    }
    
    const userData = userDoc.data();
    console.log('✅ User document found');
    console.log('📧 User email:', userData.email);
    
    if (userData.businessProfile) {
      console.log('🏢 Business profile found:');
      console.log('  Business Name:', userData.businessProfile.businessName);
      console.log('  Business Email:', userData.businessProfile.email);
      console.log('  Business Type:', userData.businessProfile.businessType);
      console.log('  Business Address:', userData.businessProfile.businessAddress);
      console.log('  Business Categories:', userData.businessProfile.businessCategories);
      console.log('  Verification Status:', userData.businessProfile.verificationStatus);
    } else {
      console.log('❌ No business profile found');
    }
    
  } catch (error) {
    console.error('❌ Error checking business profile:', error);
  }
}

checkBusinessProfile();
