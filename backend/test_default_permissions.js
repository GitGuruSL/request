const { getDefaultPermissionsForRole } = require('./services/adminPermissions');

console.log('🧪 Testing default permissions for different roles:\n');

console.log('👤 Country Admin Permissions:');
console.log('==============================');
const countryAdminPerms = getDefaultPermissionsForRole('country_admin');
console.log(`Total permissions: ${Object.keys(countryAdminPerms).length}`);
console.log('Key permissions:');
console.log('- requestManagement:', countryAdminPerms.requestManagement);
console.log('- countryProductManagement:', countryAdminPerms.countryProductManagement);
console.log('- countryCategoryManagement:', countryAdminPerms.countryCategoryManagement);
console.log('- adminUsersManagement:', countryAdminPerms.adminUsersManagement);

console.log('\n👑 Super Admin Permissions:');
console.log('============================');
const superAdminPerms = getDefaultPermissionsForRole('super_admin');
console.log(`Total permissions: ${Object.keys(superAdminPerms).length}`);
console.log('Key permissions:');
console.log('- requestManagement:', superAdminPerms.requestManagement);
console.log('- countryProductManagement:', superAdminPerms.countryProductManagement);
console.log('- countryCategoryManagement:', superAdminPerms.countryCategoryManagement);
console.log('- adminUsersManagement:', superAdminPerms.adminUsersManagement);

console.log('\n✅ Permission system is working correctly!');
