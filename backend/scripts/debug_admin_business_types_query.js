const db = require('../services/database');

async function run(role = 'super_admin', country = 'LK') {
  // Simulate hasCountryBusinessTypesTable()
  const hasCountry = await db.query('SELECT 1 FROM information_schema.tables WHERE table_schema=\'public\' AND table_name=\'country_business_types\'');
  const exists = hasCountry.rows.length > 0;
  console.log('hasCountryBusinessTypesTable =', exists);
  const params = [];
  let q = '';
  const conditions = [];
  if (exists) {
    q = `SELECT cbt.*, 
         bt.name as global_name,
         bt.description as global_description,
         bt.icon as global_icon,
         cb.name as created_by_name,
         ub.name as updated_by_name
          FROM country_business_types cbt
          LEFT JOIN business_types bt ON cbt.global_business_type_id = bt.id
          LEFT JOIN admin_users cb ON cbt.created_by = cb.id
          LEFT JOIN admin_users ub ON cbt.updated_by = ub.id`;
    if (role !== 'super_admin') {
      conditions.push('cbt.country_code = $1');
      params.push(country);
    }
    if (conditions.length) q += ' WHERE ' + conditions.join(' AND ');
    q += ' ORDER BY cbt.country_code, cbt.display_order, cbt.name';
  } else {
    q = 'SELECT bt.*, NULL::text as created_by_name, NULL::text as updated_by_name FROM business_types bt';
    if (role !== 'super_admin') {
      conditions.push('bt.country_code = $1');
      params.push(country);
    }
    if (conditions.length) q += ' WHERE ' + conditions.join(' AND ');
    q += ' ORDER BY bt.country_code, bt.display_order, bt.name';
  }
  console.log('QUERY =\n', q, '\nPARAMS=', params);
  const rows = await db.query(q, params);
  console.log('rows:', rows.rows.length);
  console.log(rows.rows.slice(0, 3));
}

run(process.argv[2] || 'super_admin', (process.argv[3] || 'LK').toUpperCase()).catch(e=>{console.error('Error:', e); process.exit(1);});
