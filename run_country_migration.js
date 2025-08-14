const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin SDK
initializeApp({
  credential: applicationDefault(),
  projectId: 'request-marketplace'
});

const db = getFirestore();

// Function to get user's country from users collection
async function getUserCountry(userId) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      return {
        countryCode: userData.countryCode || 'LK',
        countryName: userData.countryName || 'Sri Lanka'
      };
    }
  } catch (error) {
    console.error(`Error fetching user data for ${userId}:`, error);
  }
  
  // Default fallback
  return {
    countryCode: 'LK',
    countryName: 'Sri Lanka'
  };
}

// Add country support to requests collection
async function addCountryToRequests() {
  console.log('🔄 Adding country support to requests collection...');
  
  const requestsSnapshot = await db.collection('requests').get();
  
  if (requestsSnapshot.empty) {
    console.log('✅ No requests found');
    return;
  }

  console.log(`📊 Found ${requestsSnapshot.docs.length} request(s)`);

  const batch = db.batch();
  let updatedCount = 0;

  for (const doc of requestsSnapshot.docs) {
    const data = doc.data();
    const docId = doc.id;

    // Check if country field is missing
    if (!data.country && data.requesterId) {
      console.log(`🔧 Processing request: ${data.title || 'Unknown'} (ID: ${docId})`);

      const userCountry = await getUserCountry(data.requesterId);

      batch.update(doc.ref, {
        country: userCountry.countryCode,
        countryName: userCountry.countryName,
        updatedAt: new Date()
      });

      console.log(`✅ Will update request "${data.title}" with country: ${userCountry.countryName} (${userCountry.countryCode})`);
      updatedCount++;
    } else if (!data.country) {
      // No requesterId, default to Sri Lanka
      console.log(`⚠️ No requesterId found for request ${data.title}, defaulting to Sri Lanka`);
      batch.update(doc.ref, {
        country: 'LK',
        countryName: 'Sri Lanka',
        updatedAt: new Date()
      });
      updatedCount++;
    } else {
      console.log(`✅ Request "${data.title}" already has country: ${data.country}`);
    }
  }

  if (updatedCount > 0) {
    console.log(`🚀 Committing batch update for ${updatedCount} request(s)...`);
    await batch.commit();
    console.log(`✅ Successfully updated ${updatedCount} request(s) with country information`);
  } else {
    console.log('✅ All requests already have country information');
  }
}

// Add country support to responses collection
async function addCountryToResponses() {
  console.log('🔄 Adding country support to responses collection...');
  
  const responsesSnapshot = await db.collection('responses').get();
  
  if (responsesSnapshot.empty) {
    console.log('✅ No responses found');
    return;
  }

  console.log(`📊 Found ${responsesSnapshot.docs.length} response(s)`);

  const batch = db.batch();
  let updatedCount = 0;

  for (const doc of responsesSnapshot.docs) {
    const data = doc.data();
    const docId = doc.id;

    // Check if country field is missing
    if (!data.country && data.responderId) {
      console.log(`🔧 Processing response from responder: ${data.responderId} (ID: ${docId})`);

      const userCountry = await getUserCountry(data.responderId);

      batch.update(doc.ref, {
        country: userCountry.countryCode,
        countryName: userCountry.countryName,
        updatedAt: new Date()
      });

      console.log(`✅ Will update response with country: ${userCountry.countryName} (${userCountry.countryCode})`);
      updatedCount++;
    } else if (!data.country) {
      // No responderId, default to Sri Lanka
      console.log(`⚠️ No responderId found for response, defaulting to Sri Lanka`);
      batch.update(doc.ref, {
        country: 'LK',
        countryName: 'Sri Lanka',
        updatedAt: new Date()
      });
      updatedCount++;
    } else {
      console.log(`✅ Response already has country: ${data.country}`);
    }
  }

  if (updatedCount > 0) {
    console.log(`🚀 Committing batch update for ${updatedCount} response(s)...`);
    await batch.commit();
    console.log(`✅ Successfully updated ${updatedCount} response(s) with country information`);
  } else {
    console.log('✅ All responses already have country information');
  }
}

// Add country support to price_listings collection
async function addCountryToPriceListings() {
  console.log('🔄 Adding country support to price_listings collection...');
  
  const priceListingsSnapshot = await db.collection('price_listings').get();
  
  if (priceListingsSnapshot.empty) {
    console.log('✅ No price listings found');
    return;
  }

  console.log(`📊 Found ${priceListingsSnapshot.docs.length} price listing(s)`);

  const batch = db.batch();
  let updatedCount = 0;

  for (const doc of priceListingsSnapshot.docs) {
    const data = doc.data();
    const docId = doc.id;

    // Check if country field is missing
    if (!data.country && data.businessId) {
      console.log(`🔧 Processing price listing for business: ${data.businessId} (ID: ${docId})`);

      // Get business country from new_business_verifications
      try {
        const businessDoc = await db.collection('new_business_verifications').doc(data.businessId).get();
        let userCountry = { countryCode: 'LK', countryName: 'Sri Lanka' };

        if (businessDoc.exists) {
          const businessData = businessDoc.data();
          if (businessData.country) {
            userCountry = {
              countryCode: businessData.country,
              countryName: businessData.countryName || businessData.country
            };
          } else if (businessData.userId) {
            // Fallback to user's country
            userCountry = await getUserCountry(businessData.userId);
          }
        }

        batch.update(doc.ref, {
          country: userCountry.countryCode,
          countryName: userCountry.countryName,
          updatedAt: new Date()
        });

        console.log(`✅ Will update price listing with country: ${userCountry.countryName} (${userCountry.countryCode})`);
        updatedCount++;
      } catch (error) {
        console.error(`❌ Error processing price listing ${docId}:`, error);
        // Default to Sri Lanka on error
        batch.update(doc.ref, {
          country: 'LK',
          countryName: 'Sri Lanka',
          updatedAt: new Date()
        });
        updatedCount++;
      }
    } else if (!data.country) {
      // No businessId, default to Sri Lanka
      console.log(`⚠️ No businessId found for price listing, defaulting to Sri Lanka`);
      batch.update(doc.ref, {
        country: 'LK',
        countryName: 'Sri Lanka',
        updatedAt: new Date()
      });
      updatedCount++;
    } else {
      console.log(`✅ Price listing already has country: ${data.country}`);
    }
  }

  if (updatedCount > 0) {
    console.log(`🚀 Committing batch update for ${updatedCount} price listing(s)...`);
    await batch.commit();
    console.log(`✅ Successfully updated ${updatedCount} price listing(s) with country information`);
  } else {
    console.log('✅ All price listings already have country information');
  }
}

// Main migration function
async function runMigration() {
  try {
    console.log('🌍 Starting country support migration for all collections...\n');

    await addCountryToRequests();
    console.log(''); // Empty line for readability

    await addCountryToResponses();
    console.log(''); // Empty line for readability

    await addCountryToPriceListings();
    console.log(''); // Empty line for readability

    console.log('🎉 Country support migration completed successfully!');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Run the migration
runMigration()
  .then(() => {
    console.log('✅ Migration completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Migration failed:', error);
    process.exit(1);
  });
