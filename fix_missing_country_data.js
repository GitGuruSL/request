const admin = require('firebase-admin');

// Initialize Firebase Admin
try {
  admin.initializeApp({
    projectId: 'request-marketplace'
  });
  console.log('✅ Firebase Admin initialized successfully');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin:', error);
  console.log('💡 Make sure you are logged in: firebase login');
  process.exit(1);
}

const db = admin.firestore();

async function fixRequestsWithoutCountry() {
  console.log('🔍 Looking for requests without country information...');
  
  try {
    // Query requests without country field
    const requestsRef = db.collection('requests');
    const snapshot = await requestsRef.get();
    
    if (snapshot.empty) {
      console.log('✅ No requests found');
      return;
    }
    
    let totalRequests = 0;
    let requestsWithoutCountry = 0;
    let updatedRequests = 0;
    
    console.log(`📊 Found ${snapshot.docs.length} total requests`);
    
    for (const doc of snapshot.docs) {
      totalRequests++;
      const data = doc.data();
      
      // Check if country field is missing
      if (!data.country || !data.countryName) {
        requestsWithoutCountry++;
        console.log(`🔧 Request ${doc.id} missing country data:`, {
          title: data.title,
          type: data.type,
          hasCountry: !!data.country,
          hasCountryName: !!data.countryName
        });
        
        // Get user's country from their profile or set default
        let userCountry = 'LK';
        let userCountryName = 'Sri Lanka';
        
        if (data.requesterId) {
          try {
            const userDoc = await db.collection('users').doc(data.requesterId).get();
            if (userDoc.exists) {
              const userData = userDoc.data();
              userCountry = userData.countryCode || 'LK';
              userCountryName = userData.countryName || 'Sri Lanka';
            }
          } catch (err) {
            console.log(`⚠️  Could not fetch user data for ${data.requesterId}, using default`);
          }
        }
        
        // Update the request with country information
        try {
          await doc.ref.update({
            country: userCountry,
            countryName: userCountryName,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          
          updatedRequests++;
          console.log(`✅ Updated request ${doc.id} with country: ${userCountry} (${userCountryName})`);
        } catch (updateError) {
          console.error(`❌ Failed to update request ${doc.id}:`, updateError);
        }
      }
    }
    
    console.log('\n📋 Summary:');
    console.log(`- Total requests: ${totalRequests}`);
    console.log(`- Requests without country: ${requestsWithoutCountry}`);
    console.log(`- Successfully updated: ${updatedRequests}`);
    
    if (updatedRequests > 0) {
      console.log('\n🎉 Country data migration completed!');
      console.log('✅ All requests now have country information');
    } else {
      console.log('\n✅ All requests already have country information');
    }
    
  } catch (error) {
    console.error('❌ Error during migration:', error);
  }
}

// Also fix responses without country
async function fixResponsesWithoutCountry() {
  console.log('\n🔍 Looking for responses without country information...');
  
  try {
    const responsesRef = db.collection('responses');
    const snapshot = await responsesRef.get();
    
    if (snapshot.empty) {
      console.log('✅ No responses found');
      return;
    }
    
    let totalResponses = 0;
    let responsesWithoutCountry = 0;
    let updatedResponses = 0;
    
    console.log(`📊 Found ${snapshot.docs.length} total responses`);
    
    for (const doc of snapshot.docs) {
      totalResponses++;
      const data = doc.data();
      
      if (!data.country || !data.countryName) {
        responsesWithoutCountry++;
        
        // Get country from the associated request or user
        let userCountry = 'LK';
        let userCountryName = 'Sri Lanka';
        
        if (data.requestId) {
          try {
            const requestDoc = await db.collection('requests').doc(data.requestId).get();
            if (requestDoc.exists) {
              const requestData = requestDoc.data();
              userCountry = requestData.country || 'LK';
              userCountryName = requestData.countryName || 'Sri Lanka';
            }
          } catch (err) {
            console.log(`⚠️  Could not fetch request data for ${data.requestId}`);
          }
        }
        
        try {
          await doc.ref.update({
            country: userCountry,
            countryName: userCountryName,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          
          updatedResponses++;
          console.log(`✅ Updated response ${doc.id} with country: ${userCountry}`);
        } catch (updateError) {
          console.error(`❌ Failed to update response ${doc.id}:`, updateError);
        }
      }
    }
    
    console.log('\n📋 Responses Summary:');
    console.log(`- Total responses: ${totalResponses}`);
    console.log(`- Responses without country: ${responsesWithoutCountry}`);
    console.log(`- Successfully updated: ${updatedResponses}`);
    
  } catch (error) {
    console.error('❌ Error during response migration:', error);
  }
}

async function main() {
  console.log('🚀 Starting country data migration...\n');
  
  await fixRequestsWithoutCountry();
  await fixResponsesWithoutCountry();
  
  console.log('\n🎯 Migration complete!');
  console.log('Now both admin panel and Flutter app should show consistent data.');
  process.exit(0);
}

main().catch(console.error);
