// Script to add delivery role to the correct user
const fs = require('fs');

// Firebase Admin SDK setup
const admin = require('./node_modules/firebase-admin');
const serviceAccount = require('./request-marketplace-firebase-adminsdk-bj60b-95ba0f4c6d.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixUserRole() {
  const userId = 'Ey0iESw9nQfhfWoaflQmpTsBHZC3'; // Your correct user ID
  
  console.log('🔧 Fixing delivery role for user:', userId);
  
  try {
    // Get current user document
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      console.log('❌ User document not found');
      return;
    }
    
    const userData = userDoc.data();
    console.log('📋 Current user data:');
    console.log('  - Name:', userData.name || 'N/A');
    console.log('  - Current Roles:', userData.roles || []);
    console.log('  - Role Data Keys:', Object.keys(userData.roleData || {}));
    
    // Update roles array
    const currentRoles = userData.roles || ['general'];
    if (!currentRoles.includes('delivery')) {
      currentRoles.push('delivery');
      console.log('✅ Adding delivery role to roles array');
    } else {
      console.log('ℹ️ Delivery role already in roles array');
    }
    
    // Update roleData
    const currentRoleData = userData.roleData || {};
    currentRoleData.delivery = {
      verificationStatus: 'approved',
      data: {},
      verificationNotes: null,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    console.log('✅ Setting delivery role data to approved');
    
    // Update the document
    await userRef.update({
      roles: currentRoles,
      roleData: currentRoleData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('🎉 SUCCESS! User role updated successfully');
    console.log('📱 Now restart your mobile app to see the changes');
    
    // Verify the update
    const updatedDoc = await userRef.get();
    const updatedData = updatedDoc.data();
    console.log('✅ Verification - Updated Roles:', updatedData.roles);
    console.log('✅ Verification - Delivery Role Status:', updatedData.roleData?.delivery?.verificationStatus);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
  
  process.exit(0);
}

fixUserRole();
