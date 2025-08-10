// Fix Add Product Issue - Direct Firestore Script
// Run this in Firebase Console or admin panel to create product categories

const fixProductCategories = async () => {
    console.log('🔧 Fixing product categories for Add Product feature...');
    
    // Basic categories that will work immediately
    const categories = [
        {
            name: 'Electronics',
            description: 'Electronic devices and accessories',
            isActive: true,
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            name: 'Fashion',
            description: 'Clothing and fashion items',
            isActive: true,
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            name: 'Home & Garden',
            description: 'Home and garden products',
            isActive: true,
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            name: 'Automotive',
            description: 'Car parts and accessories',
            isActive: true,
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            name: 'Sports',
            description: 'Sports and recreation',
            isActive: true,
            createdAt: new Date(),
            updatedAt: new Date()
        }
    ];

    const masterProducts = [
        {
            name: 'iPhone 15 Pro',
            description: 'Latest Apple smartphone with advanced features',
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
            name: 'Nike Running Shoes',
            description: 'Comfortable sports shoes for running',
            categoryId: 'fashion',
            isActive: true,
            basePrice: 129.99,
            unit: 'pair',
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            name: 'Office Chair',
            description: 'Ergonomic office chair for work',
            categoryId: 'home',
            isActive: true,
            basePrice: 199.99,
            unit: 'piece',
            createdAt: new Date(),
            updatedAt: new Date()
        },
        {
            name: 'Car Phone Holder',
            description: 'Universal phone holder for cars',
            categoryId: 'automotive',
            isActive: true,
            basePrice: 29.99,
            unit: 'piece',
            createdAt: new Date(),
            updatedAt: new Date()
        }
    ];

    try {
        console.log('📦 Creating product categories...');
        
        // Create categories
        for (let i = 0; i < categories.length; i++) {
            const category = categories[i];
            const categoryData = {
                ...category,
                createdAt: firebase.firestore.Timestamp.fromDate(category.createdAt),
                updatedAt: firebase.firestore.Timestamp.fromDate(category.updatedAt)
            };
            
            const categoryId = category.name.toLowerCase().replace(/\s+/g, '-').replace(/&/g, '');
            
            await firebase.firestore()
                .collection('product_categories')
                .doc(categoryId)
                .set(categoryData);
                
            console.log(`✅ Created category: ${category.name} (${categoryId})`);
        }

        console.log('🛍️ Creating master products...');
        
        // Create master products
        for (let i = 0; i < masterProducts.length; i++) {
            const product = masterProducts[i];
            const productData = {
                ...product,
                createdAt: firebase.firestore.Timestamp.fromDate(product.createdAt),
                updatedAt: firebase.firestore.Timestamp.fromDate(product.updatedAt)
            };
            
            await firebase.firestore()
                .collection('master_products')
                .add(productData);
                
            console.log(`✅ Created product: ${product.name}`);
        }

        console.log('🎉 Product categories and products created successfully!');
        console.log('✅ Your "Add Product" feature should now work!');
        console.log('');
        console.log('📋 Created:');
        console.log('  • 5 Product Categories (Electronics, Fashion, Home & Garden, Automotive, Sports)');
        console.log('  • 5 Master Products (iPhone, Galaxy, Nike Shoes, Office Chair, Car Holder)');
        console.log('');
        console.log('🔄 Try clicking "Add Product" in your Flutter app now!');
        
        return { categories: categories.length, products: masterProducts.length };
    } catch (error) {
        console.error('❌ Error creating data:', error);
        throw error;
    }
};

// Auto-run the fix
console.log('🔧 Product Categories Fix Script Loaded!');
console.log('🚀 Running in 2 seconds...');

setTimeout(() => {
    if (typeof firebase !== 'undefined' && firebase.firestore) {
        fixProductCategories().catch(console.error);
    } else {
        console.log('⚠️ Firebase not detected. Run fixProductCategories() manually.');
    }
}, 2000);
