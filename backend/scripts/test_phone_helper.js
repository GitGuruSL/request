(async () => {
  const svc = require('../services/phone-helper');
  const db = require('../services/database');
  try {
    console.log('Testing detectPhoneBookSchema...');
    try {
      const res = await db.query("SELECT column_name FROM information_schema.columns WHERE table_name='user_phone_numbers'");
      console.log('user_phone_numbers columns:', res.rows.map(x=>x.column_name));
    } catch (e) {
      console.log('user_phone_numbers not accessible:', e.message);
    }
    const userId = process.argv[2] || '00000000-0000-0000-0000-000000000000';
    const personal = await svc.selectContactPhone(userId,'personal');
    const business = await svc.selectContactPhone(userId,'business');
    const driver = await svc.selectContactPhone(userId,'driver');
    console.log('selectContactPhone personal =>', personal);
    console.log('selectContactPhone business =>', business);
    console.log('selectContactPhone driver =>', driver);
    process.exit(0);
  } catch (e) {
    console.error('Test error', e);
    process.exit(1);
  }
})();
