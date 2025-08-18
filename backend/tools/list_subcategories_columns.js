require('dotenv').config();
const { Client } = require('pg');
(async () => {
  const c = new Client({
    host: process.env.PGHOST||process.env.DB_HOST,
    user: process.env.PGUSER||process.env.DB_USERNAME,
    password: process.env.PGPASSWORD||process.env.DB_PASSWORD,
    database: process.env.PGDATABASE||process.env.DB_NAME,
    port: process.env.PGPORT||process.env.DB_PORT,
    ssl:(process.env.PGSSL==='true'||process.env.DB_SSL==='true')?{rejectUnauthorized:false}:undefined
  });
  await c.connect();
  const r = await c.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name='subcategories' ORDER BY ordinal_position");
  console.table(r.rows);
  await c.end();
})();
