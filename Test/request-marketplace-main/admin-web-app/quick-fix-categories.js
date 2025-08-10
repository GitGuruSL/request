// Quick Fix: Create Basic Product Categories
// Run this script in the browser console while connected to Firebase

async function createBasicCategories() {
    console.log('🚀 Creating basic product categories...');
    
    const categories = [
        {
            id: 'electronics',
            name: 'Electronics',
            description: 'Electronic devices and accessories',
            isActive: true,
            subcategories: ['Mobile Phones', 'Laptops', 'Accessories'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            id: 'fashion',
            name: 'Fashion',
            description: 'Clothing and fashion items',
            isActive: true,
            subcategories: ['Clothing', 'Shoes', 'Accessories'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            id: 'home',
            name: 'Home & Garden',
            description: 'Home and garden products',
            isActive: true,
            subcategories: ['Furniture', 'Tools', 'Decor'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            id: 'automotive',
            name: 'Automotive',
            description: 'Car parts and accessories',
            isActive: true,
            subcategories: ['Parts', 'Accessories', 'Tools'],
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            id: 'sports',
            name: 'Sports & Recreation',
            description: 'Sports equipment and recreation',
            isActive: true,
            subcategories: ['Equipment', 'Clothing', 'Accessories'],
            createdAt: new Date(),
            updatedAt: new Date()
        }
    ];

    try {
        const batch = firebase.firestore().batch();
        
        categories.forEach((category) => {
            const docRef = firebase.firestore().collection('product_categories').doc(category.id);
            
            // Convert dates to Firestore timestamps
            const categoryData = {
                ...category,
                createdAt: firebase.firestore.Timestamp.fromDate(category.createdAt),
                updatedAt: firebase.firestore.Timestamp.fromDate(category.updatedAt)
            };
            
            batch.set(docRef, categoryData);
        });
        
        await batch.commit();
        console.log('✅ Created 5 basic product categories!');
        console.log('📦 Categories: Electronics, Fashion, Home & Garden, Automotive, Sports');
        console.log('🎉 Your Flutter app should now work when you click "Add Product"!');
        
        return categories;
    } catch (error) {
        console.error('❌ Error creating categories:', error);
        throw error;
    }
}

// Also create some basic master products
async function createBasicMasterProducts() {
    console.log('🚀 Creating basic master products...');
    
    const products = [
        {
            name: 'iPhone 15 Pro',
            description: 'Latest Apple smartphone',
            categoryId: 'electronics',
            isActive: true,
            basePrice: 999.99,
            unit: 'piece',
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            name: 'Samsung Galaxy S24',
            description: 'Premium Android smartphone',
            categoryId: 'electronics',
            isActive: true,
            basePrice: 899.99,
            unit: 'piece',
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            name: 'Nike Air Max',
            description: 'Comfortable running shoes',
            categoryId: 'fashion',
            isActive: true,
            basePrice: 129.99,
            unit: 'pair',
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            name: 'Wooden Chair',
            description: 'Comfortable dining chair',
            categoryId: 'home',
            isActive: true,
            basePrice: 89.99,
            unit: 'piece',
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            name: 'Car Air Freshener',
            description: 'Long-lasting car fragrance',
            categoryId: 'automotive',
            isActive: true,
            basePrice: 9.99,
            unit: 'piece',
            createdAt: new Date(),
            updatedAt: new Date()
        }
    ];

    try {
        const batch = firebase.firestore().batch();
        
        products.forEach((product, index) => {
            const docRef = firebase.firestore().collection('master_products').doc();
            
            // Convert dates to Firestore timestamps
            const productData = {
                ...product,
                createdAt: firebase.firestore.Timestamp.fromDate(product.createdAt),
                updatedAt: firebase.firestore.Timestamp.fromDate(product.updatedAt)
            };
            
            batch.set(docRef, productData);
        });
        
        await batch.commit();
        console.log('✅ Created 5 basic master products!');
        console.log('📱 Products: iPhone 15 Pro, Galaxy S24, Nike Air Max, Wooden Chair, Car Air Freshener');
        
        return products;
    } catch (error) {
        console.error('❌ Error creating products:', error);
        throw error;
    }
}

// Run both functions
async function setupEverything() {
    try {
        await createBasicCategories();
        await createBasicMasterProducts();
        console.log('🎉 Everything setup complete! Try "Add Product" in your Flutter app now!');
    } catch (error) {
        console.error('❌ Setup failed:', error);
    }
}

console.log('🔧 Quick Fix Script Loaded!');
console.log('📋 Available commands:');
console.log('  • createBasicCategories() - Create product categories');
console.log('  • createBasicMasterProducts() - Create sample products');
console.log('  • setupEverything() - Run both setup functions');
console.log('');
console.log('🚀 Auto-running setup in 3 seconds...');

// Auto-run after 3 seconds if in browser
setTimeout(() => {
    if (typeof firebase !== 'undefined' && firebase.firestore) {
        console.log('🔄 Auto-running setup...');
        setupEverything();
    }
}, 3000);
