// Test script to create a business with the new nested structure
// Run this in the browser console to create test data

async function createTestBusiness() {
    try {
        const testBusiness = {
            userId: 'test-user-123',
            basicInfo: {
                name: 'Test Electronics Store',
                email: 'test@electronics.com',
                phone: '+94711234567',
                description: 'A test electronics store for admin panel testing',
                website: 'https://testelectronics.com',
                address: {
                    street: '123 Main Street',
                    city: 'Colombo',
                    state: 'Western',
                    country: 'Sri Lanka',
                    postalCode: '10100'
                },
                businessType: 'retail',
                categories: ['Electronics', 'Technology']
            },
            verification: {
                isEmailVerified: true,
                isPhoneVerified: false,
                isBusinessDocumentVerified: false,
                isTaxDocumentVerified: false,
                isBankAccountVerified: false,
                overallStatus: 'pending'
            },
            businessType: 'retail',
            productCategories: ['Electronics', 'Technology'],
            settings: {
                businessHours: {
                    monday: { open: '09:00', close: '18:00', isOpen: true }
                }
            },
            analytics: {
                lastUpdated: new Date()
            },
            subscription: {
                plan: 'free',
                isActive: true
            },
            createdAt: new Date(),
            updatedAt: new Date(),
            isActive: true,
            documents: {
                businessLicense: {
                    url: 'https://example.com/license.pdf',
                    status: 'pending',
                    uploadedAt: new Date()
                }
            }
        };

        // Convert dates to Firestore timestamps
        testBusiness.createdAt = firebase.firestore.Timestamp.fromDate(testBusiness.createdAt);
        testBusiness.updatedAt = firebase.firestore.Timestamp.fromDate(testBusiness.updatedAt);
        testBusiness.analytics.lastUpdated = firebase.firestore.Timestamp.fromDate(testBusiness.analytics.lastUpdated);
        
        console.log('Creating test business:', testBusiness);
        
        const docRef = await firebase.firestore().collection('businesses').add(testBusiness);
        console.log('✅ Test business created with ID:', docRef.id);
        
        // Refresh the business list
        await loadBusinesses();
        
        return docRef.id;
    } catch (error) {
        console.error('❌ Error creating test business:', error);
    }
}

console.log('🧪 Test business creation function loaded. Run createTestBusiness() to create test data.');
