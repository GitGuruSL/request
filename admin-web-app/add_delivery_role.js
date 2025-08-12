// Simple script to add delivery role to current user
const firebaseConfig = {
  apiKey: "AIzaSyAiwCPFLu1D8s8gPqMl8oA5iRr9nCTKb3c",
  authDomain: "request-marketplace.firebaseapp.com",
  projectId: "request-marketplace",
  storageBucket: "request-marketplace.firebasestorage.app",
  messagingSenderId: "551503664846",
  appId: "1:551503664846:web:4a75ab0d8e0d1bf8fb60bf"
};

// This will be run in browser console
console.log('Copy and paste this in browser console on Firebase Console:');
console.log(`
// Initialize Firebase if not already done
if (!firebase.apps.length) {
  firebase.initializeApp(${JSON.stringify(firebaseConfig)});
}

const db = firebase.firestore();
const userId = 'G68WKHAnd8WuIlYlx8iHBO6urDy2';

async function addDeliveryRole() {
  try {
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      console.log('❌ User not found');
      return;
    }

    const userData = userDoc.data();
    const currentRoles = userData.roles || ['general'];
    const currentRoleData = userData.roleData || {};

    // Add delivery role if not present
    if (!currentRoles.includes('delivery')) {
      currentRoles.push('delivery');
      console.log('✅ Adding delivery role...');
    } else {
      console.log('ℹ️ Delivery role already exists');
    }

    // Update role data
    currentRoleData.delivery = {
      verificationStatus: 'approved',
      data: {},
      verificationNotes: null,
      verifiedAt: firebase.firestore.FieldValue.serverTimestamp()
    };

    // Update the user document
    await userRef.update({
      roles: currentRoles,
      roleData: currentRoleData,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });

    console.log('✅ Success! Delivery role added to user ' + userId);
    console.log('Updated roles:', currentRoles);
    console.log('Now restart your app to see the changes');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the function
addDeliveryRole();
`);
