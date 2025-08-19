const dbService = require('./services/database');

async function checkAdmins() {
  try {
    const result = await dbService.query('SELECT email, role, country_code, permissions FROM admin_users WHERE email = $1', ['rimas@request.lk']);
    const user = result.rows[0];
    console.log('Email:', user.email);
    console.log('Role:', user.role);
    console.log('Country:', user.country_code);
    console.log('Total permissions:', Object.keys(user.permissions || {}).length);
    console.log('');
    console.log('Country-specific permissions:');
    console.log('- countryProductManagement:', !!user.permissions?.countryProductManagement);
    console.log('- countryCategoryManagement:', !!user.permissions?.countryCategoryManagement);
    console.log('- countrySubcategoryManagement:', !!user.permissions?.countrySubcategoryManagement);
    console.log('- countryBrandManagement:', !!user.permissions?.countryBrandManagement);
    console.log('- countryVariableTypeManagement:', !!user.permissions?.countryVariableTypeManagement);
    console.log('');
    console.log('Basic permissions:');
    console.log('- requestManagement:', !!user.permissions?.requestManagement);
    console.log('- responseManagement:', !!user.permissions?.responseManagement);
    console.log('- businessManagement:', !!user.permissions?.businessManagement);
  } catch (error) {
    console.error('Error:', error.message);
  }
  process.exit(0);
}

checkAdmins();
