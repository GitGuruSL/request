// Simple Product Categories Setup
// Run this in the Firebase Console or as a Cloud Function

async function setupBasicProductCategories() {
    console.log('🚀 Setting up basic product categories...');
    
    const basicCategories = [
        {
            id: 'electronics',
            name: 'Electronics',
            description: 'Electronic devices and accessories',
            isActive: true,
            type: 'item',
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            id: 'fashion',
            name: 'Fashion',
            description: 'Clothing and accessories',
            isActive: true,
            type: 'item', 
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            id: 'home-garden',
            name: 'Home & Garden',
            description: 'Home and garden items',
            isActive: true,
            type: 'item',
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            id: 'automotive',
            name: 'Automotive',
            description: 'Car parts and accessories',
            isActive: true,
            type: 'item',
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            id: 'services',
            name: 'Services',
            description: 'Professional services',
            isActive: true,
            type: 'service',
            createdAt: new Date(),
            updatedAt: new Date()
        }
    ];

    try {
        for (const category of basicCategories) {
            // Convert dates to Firestore timestamps
            const categoryData = {
                ...category,
                createdAt: firebase.firestore.Timestamp.fromDate(category.createdAt),
                updatedAt: firebase.firestore.Timestamp.fromDate(category.updatedAt)
            };
            
            await firebase.firestore()
                .collection('product_categories')
                .doc(category.id)
                .set(categoryData);
                
            console.log(`✅ Created category: ${category.name}`);
        }
        
        console.log('🎉 Basic product categories setup complete!');
        return basicCategories;
    } catch (error) {
        console.error('❌ Error setting up categories:', error);
        throw error;
    }
}

// Run the setup
console.log('📦 Basic Product Categories Setup Script Loaded');
console.log('Run: setupBasicProductCategories()');

// Auto-run if in admin context
if (typeof firebase !== 'undefined' && firebase.firestore) {
    console.log('🔄 Auto-running setup...');
    setupBasicProductCategories().catch(console.error);
}
