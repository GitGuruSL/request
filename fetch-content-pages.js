const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, query, orderBy } = require('firebase/firestore');

// Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyD2iZWGJhKf4FHp8CU2LS92mCzHTVJW9sY",
  authDomain: "request-marketplace.firebaseapp.com",
  projectId: "request-marketplace",
  storageBucket: "request-marketplace.firebasestorage.app",
  messagingSenderId: "747327994851",
  appId: "1:747327994851:web:af5b3a8e9c57cf7df5b00a"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function fetchPages() {
  try {
    console.log('📄 Fetching all content pages from Firebase...\n');
    
    const q = query(collection(db, 'content_pages'), orderBy('createdAt', 'desc'));
    const querySnapshot = await getDocs(q);
    
    if (querySnapshot.empty) {
      console.log('❌ No pages found in the collection');
      return;
    }
    
    console.log(`📊 Found ${querySnapshot.size} pages:\n`);
    
    // Group pages by type and country
    const pages = {
      centralized: [],
      country_specific: {}
    };
    
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      const page = {
        id: doc.id,
        title: data.title,
        slug: data.slug,
        category: data.category,
        type: data.type,
        targetCountry: data.targetCountry,
        status: data.status,
        displayOrder: data.displayOrder,
        createdAt: data.createdAt?.toDate?.() || 'Unknown',
        createdBy: data.createdBy || 'Unknown'
      };
      
      if (page.type === 'centralized') {
        pages.centralized.push(page);
      } else if (page.type === 'country_specific') {
        const country = page.targetCountry || 'Unknown';
        if (!pages.country_specific[country]) {
          pages.country_specific[country] = [];
        }
        pages.country_specific[country].push(page);
      }
    });
    
    // Display centralized pages
    if (pages.centralized.length > 0) {
      console.log('🌐 CENTRALIZED PAGES (Global):');
      console.log('=====================================');
      pages.centralized.forEach((page, index) => {
        console.log(`${index + 1}. ${page.title}`);
        console.log(`   Slug: ${page.slug}`);
        console.log(`   Category: ${page.category}`);
        console.log(`   Status: ${page.status}`);
        console.log(`   Created: ${page.createdAt}`);
        console.log(`   Created by: ${page.createdBy}`);
        console.log('   ---');
      });
      console.log('');
    }
    
    // Display country-specific pages
    if (Object.keys(pages.country_specific).length > 0) {
      console.log('🏳️ COUNTRY-SPECIFIC PAGES:');
      console.log('===============================');
      for (const [country, countryPages] of Object.entries(pages.country_specific)) {
        console.log(`\n📍 ${country}:`);
        countryPages.forEach((page, index) => {
          console.log(`  ${index + 1}. ${page.title}`);
          console.log(`     Slug: ${page.slug}`);
          console.log(`     Category: ${page.category}`);
          console.log(`     Status: ${page.status}`);
          console.log(`     Created: ${page.createdAt}`);
          console.log(`     Created by: ${page.createdBy}`);
          console.log('     ---');
        });
      }
    }
    
    // Summary for Flutter app
    console.log('\n📱 FOR FLUTTER APP:');
    console.log('===================');
    console.log(`✅ Total pages available: ${querySnapshot.size}`);
    console.log(`✅ Centralized pages: ${pages.centralized.length}`);
    console.log(`✅ Country-specific pages: ${Object.values(pages.country_specific).flat().length}`);
    console.log(`✅ Countries with local content: ${Object.keys(pages.country_specific).join(', ')}`);
    
    // Test content service logic
    console.log('\n🧪 CONTENT SERVICE TEST:');
    console.log('========================');
    
    // Simulate LK user
    const lkPages = [
      ...pages.centralized.filter(p => p.status === 'published'),
      ...(pages.country_specific['LK'] || []).filter(p => p.status === 'published')
    ];
    
    console.log(`For LK users: ${lkPages.length} pages available`);
    lkPages.forEach(page => {
      console.log(`  - ${page.title} (${page.type})`);
    });
    
    // Simulate global user
    const globalPages = pages.centralized.filter(p => p.status === 'published');
    console.log(`\nFor global users: ${globalPages.length} pages available`);
    globalPages.forEach(page => {
      console.log(`  - ${page.title} (${page.type})`);
    });
    
  } catch (error) {
    console.error('❌ Error fetching pages:', error);
  }
}

// Run the script
fetchPages();
