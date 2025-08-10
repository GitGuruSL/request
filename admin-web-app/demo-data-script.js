// Demo Script: Populate Sample Data for Business Product Approval Workflow
// This script creates sample master products and categories for testing

console.log('🚀 Starting demo data population...');

// Sample categories
const sampleCategories = [
  {
    name: 'Electronics',
    description: 'Electronic devices and accessories',
    iconUrl: 'https://via.placeholder.com/50x50?text=📱',
    isActive: true,
    metadata: { color: '#3B82F6' }
  },
  {
    name: 'Home & Garden',
    description: 'Home improvement and garden supplies',
    iconUrl: 'https://via.placeholder.com/50x50?text=🏡',
    isActive: true,
    metadata: { color: '#10B981' }
  },
  {
    name: 'Automotive',
    description: 'Car parts and automotive accessories',
    iconUrl: 'https://via.placeholder.com/50x50?text=🚗',
    isActive: true,
    metadata: { color: '#F59E0B' }
  },
  {
    name: 'Sports & Outdoors',
    description: 'Sports equipment and outdoor gear',
    iconUrl: 'https://via.placeholder.com/50x50?text=⚽',
    isActive: true,
    metadata: { color: '#EF4444' }
  }
];

// Sample master products
const sampleMasterProducts = [
  {
    name: 'iPhone 15 Pro',
    description: 'Latest iPhone with advanced camera system and titanium design',
    categoryId: '', // Will be filled with Electronics category ID
    subcategoryId: 'smartphones',
    brand: 'Apple',
    specifications: {
      'Screen Size': '6.1 inches',
      'Storage': '128GB, 256GB, 512GB, 1TB',
      'Camera': '48MP Main, 12MP Ultra Wide, 12MP Telephoto',
      'Battery': 'Up to 23 hours video playback',
      'Operating System': 'iOS 17'
    },
    imageUrls: ['https://via.placeholder.com/300x300?text=iPhone+15+Pro'],
    keywords: ['iphone', 'smartphone', 'apple', 'mobile', 'phone'],
    isActive: true
  },
  {
    name: 'Samsung Galaxy S24 Ultra',
    description: 'Premium Android smartphone with S Pen and AI features',
    categoryId: '', // Will be filled with Electronics category ID
    subcategoryId: 'smartphones',
    brand: 'Samsung',
    specifications: {
      'Screen Size': '6.8 inches',
      'Storage': '256GB, 512GB, 1TB',
      'Camera': '200MP Main, 50MP Periscope Telephoto, 10MP Telephoto, 12MP Ultra Wide',
      'Battery': '5000mAh',
      'Operating System': 'Android 14'
    },
    imageUrls: ['https://via.placeholder.com/300x300?text=Galaxy+S24+Ultra'],
    keywords: ['samsung', 'galaxy', 'android', 'smartphone', 'spen'],
    isActive: true
  },
  {
    name: 'MacBook Pro 16-inch',
    description: 'Powerful laptop for professionals with M3 Pro or M3 Max chip',
    categoryId: '', // Will be filled with Electronics category ID
    subcategoryId: 'laptops',
    brand: 'Apple',
    specifications: {
      'Processor': 'Apple M3 Pro or M3 Max',
      'Memory': '18GB, 36GB, 128GB unified memory',
      'Storage': '512GB, 1TB, 2TB, 4TB, 8TB SSD',
      'Display': '16.2-inch Liquid Retina XDR',
      'Battery': 'Up to 22 hours video playback'
    },
    imageUrls: ['https://via.placeholder.com/300x300?text=MacBook+Pro+16'],
    keywords: ['macbook', 'laptop', 'apple', 'professional', 'm3'],
    isActive: true
  },
  {
    name: 'Cordless Drill Set',
    description: 'Professional 20V cordless drill with battery and charger',
    categoryId: '', // Will be filled with Home & Garden category ID
    subcategoryId: 'tools',
    brand: 'DeWalt',
    specifications: {
      'Voltage': '20V MAX',
      'Chuck Size': '1/2 inch',
      'Torque Settings': '15 + 1',
      'Battery': '2.0Ah Lithium-Ion',
      'LED Light': 'Yes'
    },
    imageUrls: ['https://via.placeholder.com/300x300?text=Cordless+Drill'],
    keywords: ['drill', 'cordless', 'dewalt', 'tool', 'battery'],
    isActive: true
  },
  {
    name: 'Car Brake Pads Set',
    description: 'High-quality ceramic brake pads for improved stopping power',
    categoryId: '', // Will be filled with Automotive category ID
    subcategoryId: 'brakes',
    brand: 'Brembo',
    specifications: {
      'Material': 'Ceramic',
      'Compatibility': 'Multiple vehicle models',
      'Package': 'Set of 4 pads',
      'Warranty': '2 years or 50,000 miles',
      'Noise Level': 'Low noise formula'
    },
    imageUrls: ['https://via.placeholder.com/300x300?text=Brake+Pads'],
    keywords: ['brake', 'pads', 'ceramic', 'brembo', 'automotive'],
    isActive: true
  },
  {
    name: 'Professional Basketball',
    description: 'Official size and weight basketball for indoor/outdoor play',
    categoryId: '', // Will be filled with Sports category ID
    subcategoryId: 'basketball',
    brand: 'Spalding',
    specifications: {
      'Size': 'Official (29.5 inches)',
      'Material': 'Composite leather',
      'Surface': 'Indoor/Outdoor',
      'Weight': '22 oz',
      'Grip': 'Deep channel design'
    },
    imageUrls: ['https://via.placeholder.com/300x300?text=Basketball'],
    keywords: ['basketball', 'spalding', 'sports', 'official', 'indoor', 'outdoor'],
    isActive: true
  }
];

// Sample business data for testing
const sampleBusiness = {
  businessName: 'TechMart Solutions',
  email: 'contact@techmart.com',
  phone: '+1-555-0123',
  address: '123 Commerce Street, Business District, NY 10001',
  category: 'Electronics Retailer',
  description: 'Leading retailer of consumer electronics and tech accessories',
  verified: true,
  status: 'approved'
};

// Function to populate data
async function populateDemoData() {
  try {
    console.log('📦 Creating product categories...');
    
    // Create categories
    const categoryIds = {};
    for (const category of sampleCategories) {
      const categoryData = {
        ...category,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      const categoryRef = await db.collection('product_categories').add(categoryData);
      categoryIds[category.name] = categoryRef.id;
      console.log(`✅ Created category: ${category.name} (${categoryRef.id})`);
    }
    
    console.log('🎯 Creating master products...');
    
    // Create master products
    const masterProductIds = [];
    for (const product of sampleMasterProducts) {
      // Assign category ID based on product type
      let categoryId = '';
      if (product.name.includes('iPhone') || product.name.includes('Galaxy') || product.name.includes('MacBook')) {
        categoryId = categoryIds['Electronics'];
      } else if (product.name.includes('Drill')) {
        categoryId = categoryIds['Home & Garden'];
      } else if (product.name.includes('Brake')) {
        categoryId = categoryIds['Automotive'];
      } else if (product.name.includes('Basketball')) {
        categoryId = categoryIds['Sports & Outdoors'];
      }
      
      const productData = {
        ...product,
        categoryId,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      const productRef = await db.collection('master_products').add(productData);
      masterProductIds.push(productRef.id);
      console.log(`✅ Created master product: ${product.name} (${productRef.id})`);
    }
    
    console.log('🏪 Creating sample business...');
    
    // Create sample business
    const businessData = {
      ...sampleBusiness,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    const businessRef = await db.collection('businesses').add(businessData);
    console.log(`✅ Created business: ${sampleBusiness.businessName} (${businessRef.id})`);
    
    console.log('💰 Creating sample business product submissions...');
    
    // Create some sample business product submissions for testing approval workflow
    const sampleBusinessProducts = [
      {
        masterProductId: masterProductIds[0], // iPhone 15 Pro
        businessId: businessRef.id,
        price: 999.99,
        stock: 25,
        available: true,
        businessNotes: 'Brand new, sealed in box. Fast shipping available.',
        status: 'pending'
      },
      {
        masterProductId: masterProductIds[1], // Galaxy S24 Ultra
        businessId: businessRef.id,
        price: 1199.99,
        stock: 15,
        available: true,
        businessNotes: 'Latest model with all color options available.',
        status: 'pending'
      },
      {
        masterProductId: masterProductIds[3], // Cordless Drill
        businessId: businessRef.id,
        price: 149.99,
        stock: 50,
        available: true,
        businessNotes: 'Professional grade tool with 2-year warranty.',
        status: 'approved'
      }
    ];
    
    for (const businessProduct of sampleBusinessProducts) {
      const businessProductData = {
        ...businessProduct,
        createdAt: new Date(),
        updatedAt: new Date(),
        submittedBy: 'demo@techmart.com'
      };
      
      const bpRef = await db.collection('business_products').add(businessProductData);
      console.log(`✅ Created business product submission: ${businessProduct.status} (${bpRef.id})`);
    }
    
    console.log('🎉 Demo data population completed successfully!');
    console.log(`
    📊 Summary:
    - ${sampleCategories.length} product categories created
    - ${sampleMasterProducts.length} master products created
    - 1 sample business created
    - ${sampleBusinessProducts.length} business product submissions created
    
    📱 You can now:
    1. View products in the admin panel
    2. Test the approval workflow
    3. Use the mobile app to browse approved products
    4. Add pricing as a business user
    `);
    
  } catch (error) {
    console.error('❌ Error populating demo data:', error);
  }
}

// Export the function for use
window.populateDemoData = populateDemoData;

console.log('✅ Demo data script loaded. Call populateDemoData() to create sample data.');
