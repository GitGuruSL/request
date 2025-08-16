const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, query, where } = require('firebase/firestore');

const firebaseConfig = { 
  projectId: 'request-marketplace'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function testVehicleManagementData() {
  console.log('🔧 Testing Vehicle Management data access...\n');
  
  try {
    // Test 1: Check vehicle types collection
    console.log('📋 Test 1: Checking vehicle types');
    const vehicleTypesSnapshot = await getDocs(collection(db, 'vehicle_types'));
    const vehicleTypes = {};
    vehicleTypesSnapshot.docs.forEach(doc => {
      const data = doc.data();
      vehicleTypes[doc.id] = data.name;
      console.log(`  ${doc.id}: ${data.name} (Active: ${data.isActive})`);
    });
    
    // Test 2: Check driver verifications 
    console.log('\n👥 Test 2: Checking driver verifications');
    const driversSnapshot = await getDocs(collection(db, 'new_driver_verifications'));
    console.log(`Total drivers: ${driversSnapshot.docs.length}`);
    
    // Group by country and status
    const countryStats = {};
    const statusStats = {};
    
    driversSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const country = data.country || 'Unknown';
      const status = data.status || 'Unknown';
      const vehicleType = vehicleTypes[data.vehicleType] || 'Unknown';
      
      // Country stats
      if (!countryStats[country]) {
        countryStats[country] = { total: 0, approved: 0, vehicleTypes: {} };
      }
      countryStats[country].total++;
      if (status === 'approved') {
        countryStats[country].approved++;
      }
      
      // Vehicle type stats by country
      if (!countryStats[country].vehicleTypes[vehicleType]) {
        countryStats[country].vehicleTypes[vehicleType] = 0;
      }
      countryStats[country].vehicleTypes[vehicleType]++;
      
      // Status stats
      statusStats[status] = (statusStats[status] || 0) + 1;
    });
    
    console.log('\n📊 Country breakdown:');
    Object.entries(countryStats).forEach(([country, stats]) => {
      console.log(`  ${country}:`);
      console.log(`    Total: ${stats.total} | Approved: ${stats.approved}`);
      console.log(`    Vehicle types:`);
      Object.entries(stats.vehicleTypes).forEach(([type, count]) => {
        console.log(`      ${type}: ${count}`);
      });
    });
    
    console.log('\n📈 Status breakdown:');
    Object.entries(statusStats).forEach(([status, count]) => {
      console.log(`  ${status}: ${count}`);
    });
    
    // Test 3: LK specific data (for country admin view)
    console.log('\n🇱🇰 Test 3: LK-specific data (Country Admin view)');
    const lkDriversQuery = query(
      collection(db, 'new_driver_verifications'),
      where('country', '==', 'LK')
    );
    const lkSnapshot = await getDocs(lkDriversQuery);
    
    console.log(`LK drivers: ${lkSnapshot.docs.length}`);
    const lkVehicleTypes = {};
    lkSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const vehicleType = vehicleTypes[data.vehicleType] || 'Unknown';
      lkVehicleTypes[vehicleType] = (lkVehicleTypes[vehicleType] || 0) + 1;
    });
    
    console.log('LK vehicle breakdown:');
    Object.entries(lkVehicleTypes).forEach(([type, count]) => {
      console.log(`  ${type}: ${count}`);
    });
    
    console.log('\n✅ Vehicle Management should show:');
    console.log('  • Global Admin: All countries and vehicles');
    console.log('  • Country Admin (LK): Only LK vehicles');
    console.log('  • Vehicle counts by type and status');
    console.log('  • Driver details and vehicle information');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

testVehicleManagementData().catch(console.error);
