const admin = require('firebase-admin');
const fs = require('fs').promises;
const path = require('path');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
    try {
        const serviceAccount = require('../functions/serviceAccountKey.json');
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
        console.log('✅ Firebase Admin initialized successfully');
    } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin:', error.message);
        process.exit(1);
    }
}

const db = admin.firestore();

// Collections to export based on your Firebase structure
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
        
        const snapshot = await db.collection(collectionName).get();
        const documents = [];
        
        snapshot.forEach(doc => {
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
    
    if (obj instanceof admin.firestore.Timestamp) {
        return obj.toDate().toISOString();
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
    console.log('🚀 Starting Firebase data export...');
    console.log('=====================================');
    
    const exportSummary = {
        startTime: new Date().toISOString(),
        collections: {},
        totalDocuments: 0,
        errors: []
    };
    
    for (const collection of COLLECTIONS) {
        try {
            const count = await exportCollection(collection);
            exportSummary.collections[collection] = count;
            exportSummary.totalDocuments += count;
        } catch (error) {
            console.error(`❌ Failed to export ${collection}:`, error.message);
            exportSummary.errors.push({
                collection,
                error: error.message
            });
        }
    }
    
    exportSummary.endTime = new Date().toISOString();
    
    // Save export summary
    const summaryPath = path.join(__dirname, 'firebase-export', '_export_summary.json');
    await fs.writeFile(summaryPath, JSON.stringify(exportSummary, null, 2));
    
    // Display summary
    console.log('\n=====================================');
    console.log('📊 Export Summary');
    console.log('=====================================');
    console.log(`Total Collections: ${COLLECTIONS.length}`);
    console.log(`Total Documents: ${exportSummary.totalDocuments}`);
    console.log(`Export Duration: ${new Date(exportSummary.endTime) - new Date(exportSummary.startTime)} ms`);
    
    if (exportSummary.errors.length > 0) {
        console.log('\n❌ Errors:');
        exportSummary.errors.forEach(error => {
            console.log(`   ${error.collection}: ${error.error}`);
        });
    }
    
    console.log('\n📁 Export files saved to: ./migration/firebase-export/');
    console.log('✅ Firebase export complete!');
    
    // Create data validation script
    await createValidationScript(exportSummary);
}

async function createValidationScript(summary) {
    const validationScript = `
const fs = require('fs');
const path = require('path');

// Export summary from Firebase
const EXPORT_SUMMARY = ${JSON.stringify(summary, null, 2)};

async function validateExport() {
    console.log('🔍 Validating Firebase export...');
    
    const exportDir = path.join(__dirname, 'firebase-export');
    let isValid = true;
    
    for (const [collection, expectedCount] of Object.entries(EXPORT_SUMMARY.collections)) {
        const filePath = path.join(exportDir, \`\${collection}.json\`);
        
        try {
            const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
            const actualCount = data.length;
            
            if (actualCount === expectedCount) {
                console.log(\`✅ \${collection}: \${actualCount} documents\`);
            } else {
                console.log(\`❌ \${collection}: Expected \${expectedCount}, got \${actualCount}\`);
                isValid = false;
            }
        } catch (error) {
            console.log(\`❌ \${collection}: File not found or invalid JSON\`);
            isValid = false;
        }
    }
    
    if (isValid) {
        console.log('\\n✅ All export files validated successfully!');
        console.log('🔜 Ready for Phase 3: Data Transformation');
    } else {
        console.log('\\n❌ Export validation failed. Please re-export missing collections.');
    }
    
    return isValid;
}

if (require.main === module) {
    validateExport();
}

module.exports = { validateExport, EXPORT_SUMMARY };
`;
    
    const scriptPath = path.join(__dirname, 'validate-export.js');
    await fs.writeFile(scriptPath, validationScript);
    console.log('📝 Created validation script: validate-export.js');
}

// Run the export
if (require.main === module) {
    exportAllCollections()
        .then(() => {
            console.log('🎉 Export process completed successfully!');
            process.exit(0);
        })
        .catch(error => {
            console.error('💥 Export process failed:', error);
            process.exit(1);
        });
}

module.exports = { exportAllCollections, exportCollection };
