// Driver Data Debug Script - Add this to browser console to inspect driver data structure

function debugDriverData() {
    console.log('🔍 DRIVER DATA DEBUG SCRIPT');
    console.log('============================');
    
    // This will help identify the actual structure of driver documents
    // Run this in browser console when viewing driver details
    
    if (typeof db !== 'undefined') {
        // Get all drivers to inspect their structure
        getDocs(query(collection(db, 'drivers')))
            .then(snapshot => {
                snapshot.docs.forEach(doc => {
                    const data = doc.data();
                    console.log(`\n🚗 Driver: ${data.name || 'Unknown'}`);
                    console.log('📊 Full data structure:', data);
                    
                    // Check image fields
                    console.log('🖼️ Image Fields:');
                    if (data.photoUrl) console.log('  - photoUrl:', data.photoUrl);
                    if (data.driverImageUrls) console.log('  - driverImageUrls:', data.driverImageUrls);
                    if (data.vehicleImageUrls) console.log('  - vehicleImageUrls:', data.vehicleImageUrls);
                    if (data.documentImageUrls) console.log('  - documentImageUrls:', data.documentImageUrls);
                    
                    // Check document verification structure
                    console.log('📄 Document Verification:');
                    if (data.documentVerification) {
                        console.log('  - documentVerification:', data.documentVerification);
                    } else {
                        console.log('  - documentVerification: NOT PRESENT (this is the issue!)');
                    }
                    
                    console.log('------------------------');
                });
            })
            .catch(error => {
                console.error('Error fetching drivers:', error);
            });
    } else {
        console.error('Firebase db not available. Make sure you are on the admin panel page.');
    }
}

// Auto-run if in browser
if (typeof window !== 'undefined') {
    console.log('🔧 Driver verification debug script loaded');
    console.log('💡 Run debugDriverData() to inspect driver data structures');
}
