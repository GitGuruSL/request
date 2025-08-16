// Alternative Firebase export using web SDK instead of Admin SDK
const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');
const fs = require('fs').promises;
const path = require('path');

// Firebase configuration from your Flutter app
const firebaseConfig = {
    apiKey: 'AIzaSyC5hb6Ydkp__EZgX-kRjJgtOKZKg8TNkJg',
    authDomain: 'request-marketplace.firebaseapp.com',
    projectId: 'request-marketplace',
    storageBucket: 'request-marketplace.firebasestorage.app',
    messagingSenderId: '635550436472',
    appId: '1:635550436472:web:72ee20ad95cdcf65c1c86a'
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Collections to export
const COLLECTIONS = [
    'users',
    'categories',
    'subcategories', 
    'cities',
    'vehicle_types',
    'country_vehicle_types',
    'country_vehicles',
    'variable_types',
    'country_variable_types',
    'requests',
    'new_business_verifications',
    'new_driver_verifications',
    'price_listings',
    'conversations',
    'messages',
    'notifications',
    'subscription_plans',
    'content_pages',
    'email_otp_verifications',
    'phone_otp_verifications',
    'phone_verifications',
    'response_tracking',
    'ride_tracking',
    'country_brands',
    'country_categories',
    'country_modules',
    'country_products',
    'country_subcategories',
    'custom_product_variables',
    'master_products',
    'test'
];

async function exportCollection(collectionName) {
    try {
        console.log(`📦 Exporting collection: ${collectionName}`);
        
        const querySnapshot = await getDocs(collection(db, collectionName));
        const documents = [];
        
        querySnapshot.forEach((doc) => {
            const data = doc.data();
            
            // Convert Firestore Timestamps to ISO strings
            const convertedData = convertTimestamps(data);
            
            documents.push({
                id: doc.id,
                ...convertedData
            });
        });
        
        // Create export directory if it doesn't exist
        const exportDir = path.join(__dirname, 'firebase-export');
        await fs.mkdir(exportDir, { recursive: true });
        
        // Write to JSON file
        const filePath = path.join(exportDir, `${collectionName}.json`);
        await fs.writeFile(filePath, JSON.stringify(documents, null, 2));
        
        console.log(`✅ Exported ${documents.length} documents from ${collectionName}`);
        return documents.length;
        
    } catch (error) {
        console.error(`❌ Error exporting ${collectionName}:`, error.message);
        return 0;
    }
}

function convertTimestamps(obj) {
    if (obj === null || obj === undefined) {
        return obj;
    }
    
    // Handle Firestore Timestamp objects
    if (obj && typeof obj === 'object' && obj.seconds !== undefined && obj.nanoseconds !== undefined) {
        return new Date(obj.seconds * 1000 + obj.nanoseconds / 1000000).toISOString();
    }
    
    if (obj instanceof Date) {
        return obj.toISOString();
    }
    
    if (Array.isArray(obj)) {
        return obj.map(convertTimestamps);
    }
    
    if (typeof obj === 'object') {
        const converted = {};
        for (const [key, value] of Object.entries(obj)) {
            converted[key] = convertTimestamps(value);
        }
        return converted;
    }
    
    return obj;
}

async function exportAllCollections() {
    console.log('🚀 Starting Firebase data export (Web SDK)...');
    console.log('===============================================');
    
    const exportSummary = {
        startTime: new Date().toISOString(),
        collections: {},
        totalDocuments: 0,
        errors: []
    };
    
    for (const collectionName of COLLECTIONS) {
        try {
            const count = await exportCollection(collectionName);
            exportSummary.collections[collectionName] = count;
            exportSummary.totalDocuments += count;
        } catch (error) {
            console.error(`❌ Failed to export ${collectionName}:`, error.message);
            exportSummary.errors.push({
                collection: collectionName,
                error: error.message
            });
        }
    }
    
    exportSummary.endTime = new Date().toISOString();
    
    // Save export summary
    const exportDir = path.join(__dirname, 'firebase-export');
    const summaryPath = path.join(exportDir, '_export_summary.json');
    await fs.writeFile(summaryPath, JSON.stringify(exportSummary, null, 2));
    
    // Display summary
    console.log('\n===============================================');
    console.log('📊 Export Summary');
    console.log('===============================================');
    console.log(`Total Collections: ${COLLECTIONS.length}`);
    console.log(`Total Documents: ${exportSummary.totalDocuments}`);
    console.log(`Export Duration: ${new Date(exportSummary.endTime) - new Date(exportSummary.startTime)} ms`);
    
    if (exportSummary.errors.length > 0) {
        console.log('\n❌ Errors:');
        exportSummary.errors.forEach(error => {
            console.log(`   ${error.collection}: ${error.error}`);
        });
    }
    
    console.log('\n📁 Export files saved to: ./firebase-export/');
    console.log('✅ Firebase export complete!');
    
    return exportSummary;
}

// Run the export
if (require.main === module) {
    exportAllCollections()
        .then((summary) => {
            console.log('\n🎉 Export process completed successfully!');
            console.log(`📊 Exported ${summary.totalDocuments} documents from ${Object.keys(summary.collections).length} collections`);
            
            console.log('\n🔜 Next Steps:');
            console.log('   1. Review exported data in ./firebase-export/');
            console.log('   2. Transform data: node transform-data.js');
            console.log('   3. Import to PostgreSQL: node import-data.js');
            
            process.exit(0);
        })
        .catch(error => {
            console.error('💥 Export process failed:', error);
            process.exit(1);
        });
}

module.exports = { exportAllCollections, exportCollection };
