const admin = require('firebase-admin');

// Initialize Firebase Admin SDK with application default credentials
// This will work if you're logged in via Firebase CLI
try {
  admin.initializeApp({
    projectId: 'request-marketplace'
  });
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK:', error);
  console.log('💡 Make sure you are logged in to Firebase CLI: firebase login');
  process.exit(1);
}

const db = admin.firestore();

async function migrateBusinessCountries() {
  try {
    console.log('🔄 Starting business country migration...');

    // Get all business verifications that are missing country field
    const businessesSnapshot = await db.collection('new_business_verifications').get();
    
    if (businessesSnapshot.empty) {
      console.log('❌ No business verifications found');
      return;
    }

    console.log(`📊 Found ${businessesSnapshot.docs.length} business verification(s)`);

    const batch = db.batch();
    let updatedCount = 0;

    for (const doc of businessesSnapshot.docs) {
      const data = doc.data();
      const docId = doc.id;

      // Check if country field is missing
      if (!data.country) {
        console.log(`🔧 Processing business: ${data.businessName || 'Unknown'} (ID: ${docId})`);

        // Get the user's country from users collection
        if (data.userId) {
          try {
            const userDoc = await db.collection('users').doc(data.userId).get();
            if (userDoc.exists) {
              const userData = userDoc.data();
              const userCountryCode = userData.countryCode;
              const userCountryName = userData.countryName;

              if (userCountryCode && userCountryName) {
                // Update business with user's country info
                batch.update(doc.ref, {
                  country: userCountryCode,
                  countryName: userCountryName,
                  updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });

                console.log(`✅ Will update ${data.businessName} with country: ${userCountryName} (${userCountryCode})`);
                updatedCount++;
              } else if (userCountryCode) {
                // If we have country code but not name, try to map it
                let countryName = 'Unknown';
                switch (userCountryCode) {
                  case 'LK': countryName = 'Sri Lanka'; break;
                  case 'US': countryName = 'United States'; break;
                  case 'GB': countryName = 'United Kingdom'; break;
                  case 'IN': countryName = 'India'; break;
                  // Add more mappings as needed
                }

                batch.update(doc.ref, {
                  country: userCountryCode,
                  countryName: countryName,
                  updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });

                console.log(`✅ Will update ${data.businessName} with country: ${countryName} (${userCountryCode})`);
                updatedCount++;
              } else {
                // Default to Sri Lanka if no country info found
                console.log(`⚠️ No country info found for user ${data.userId}, defaulting to Sri Lanka`);
                batch.update(doc.ref, {
                  country: 'LK',
                  countryName: 'Sri Lanka',
                  updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                updatedCount++;
              }
            } else {
              // User document doesn't exist, default to Sri Lanka
              console.log(`⚠️ User document not found for ${data.userId}, defaulting to Sri Lanka`);
              batch.update(doc.ref, {
                country: 'LK',
                countryName: 'Sri Lanka',
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
              });
              updatedCount++;
            }
          } catch (userError) {
            console.error(`❌ Error fetching user data for ${data.userId}:`, userError);
            // Default to Sri Lanka on error
            batch.update(doc.ref, {
              country: 'LK',
              countryName: 'Sri Lanka',
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            updatedCount++;
          }
        } else {
          // No userId, default to Sri Lanka
          console.log(`⚠️ No userId found for business ${data.businessName}, defaulting to Sri Lanka`);
          batch.update(doc.ref, {
            country: 'LK',
            countryName: 'Sri Lanka',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          updatedCount++;
        }
      } else {
        console.log(`✅ Business ${data.businessName} already has country: ${data.country}`);
      }
    }

    if (updatedCount > 0) {
      console.log(`🚀 Committing batch update for ${updatedCount} business(es)...`);
      await batch.commit();
      console.log(`✅ Successfully updated ${updatedCount} business verification(s) with country information`);
    } else {
      console.log('✅ All businesses already have country information');
    }

  } catch (error) {
    console.error('❌ Error during migration:', error);
  }
}

// Run the migration
migrateBusinessCountries()
  .then(() => {
    console.log('🎉 Migration completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Migration failed:', error);
    process.exit(1);
  });
