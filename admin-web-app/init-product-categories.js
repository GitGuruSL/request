// Product Categories Initialization Script
// Run this in the browser console on your admin panel to populate product categories

async function initializeProductCategories() {
    console.log('🚀 Initializing product categories...');
    
    const categories = [
        // Electronics & Technology
        {
            id: 'electronics',
            name: 'Electronics',
            description: 'Electronic devices and gadgets',
            icon: '📱',
            isActive: true,
            subcategories: ['Mobile Phones', 'Laptops', 'Tablets', 'Accessories'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            id: 'computers',
            name: 'Computers & IT',
            description: 'Computer hardware and software',
            icon: '💻',
            isActive: true,
            subcategories: ['Desktops', 'Laptops', 'Components', 'Software'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        
        // Fashion & Clothing
        {
            id: 'fashion',
            name: 'Fashion & Clothing',
            description: 'Clothing and fashion accessories',
            icon: '👕',
            isActive: true,
            subcategories: ['Men\'s Clothing', 'Women\'s Clothing', 'Shoes', 'Accessories'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        
        // Home & Garden
        {
            id: 'home-garden',
            name: 'Home & Garden',
            description: 'Home improvement and garden supplies',
            icon: '🏠',
            isActive: true,
            subcategories: ['Furniture', 'Decor', 'Garden Tools', 'Appliances'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        
        // Food & Beverages
        {
            id: 'food-beverages',
            name: 'Food & Beverages',
            description: 'Food items and beverages',
            icon: '🍕',
            isActive: true,
            subcategories: ['Fresh Food', 'Packaged Food', 'Beverages', 'Snacks'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        
        // Health & Beauty
        {
            id: 'health-beauty',
            name: 'Health & Beauty',
            description: 'Health and beauty products',
            icon: '💄',
            isActive: true,
            subcategories: ['Skincare', 'Makeup', 'Health Supplements', 'Personal Care'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        
        // Sports & Recreation
        {
            id: 'sports',
            name: 'Sports & Recreation',
            description: 'Sports equipment and recreational items',
            icon: '⚽',
            isActive: true,
            subcategories: ['Fitness Equipment', 'Sports Gear', 'Outdoor Recreation', 'Team Sports'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        
        // Automotive
        {
            id: 'automotive',
            name: 'Automotive',
            description: 'Car parts and automotive accessories',
            icon: '🚗',
            isActive: true,
            subcategories: ['Car Parts', 'Accessories', 'Tools', 'Maintenance'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        
        // Books & Media
        {
            id: 'books-media',
            name: 'Books & Media',
            description: 'Books, movies, and media content',
            icon: '📚',
            isActive: true,
            subcategories: ['Books', 'Movies', 'Music', 'Games'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        
        // Services
        {
            id: 'services',
            name: 'Services',
            description: 'Professional and personal services',
            icon: '🔧',
            isActive: true,
            subcategories: ['Repair Services', 'Cleaning', 'Consulting', 'Education'],
            createdAt: new Date(),
            updatedAt: new Date()
        }
    ];

    try {
        const batch = firebase.firestore().batch();
        
        categories.forEach((category) => {
            // Convert dates to Firestore timestamps
            category.createdAt = firebase.firestore.Timestamp.fromDate(category.createdAt);
            category.updatedAt = firebase.firestore.Timestamp.fromDate(category.updatedAt);
            
            const docRef = firebase.firestore().collection('product_categories').doc(category.id);
            batch.set(docRef, category);
        });
        
        await batch.commit();
        console.log('✅ Product categories initialized successfully!');
        console.log(`📊 Created ${categories.length} categories`);
        
        // List all categories
        console.log('📋 Categories created:');
        categories.forEach(cat => console.log(`  ${cat.icon} ${cat.name}`));
        
        return categories;
    } catch (error) {
        console.error('❌ Error initializing product categories:', error);
    }
}

// Function to check existing categories
async function checkProductCategories() {
    try {
        const snapshot = await firebase.firestore().collection('product_categories').get();
        console.log(`📊 Found ${snapshot.size} product categories`);
        
        snapshot.forEach(doc => {
            const data = doc.data();
            console.log(`  ${data.icon || '📦'} ${data.name} (${doc.id})`);
        });
        
        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('❌ Error checking product categories:', error);
    }
}

console.log('🧪 Product Categories Manager loaded!');
console.log('📋 Available commands:');
console.log('  • initializeProductCategories() - Create all product categories');
console.log('  • checkProductCategories() - List existing categories');
