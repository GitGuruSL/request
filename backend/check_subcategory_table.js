const dbService = require('./services/database');

async function checkSubcategoryTable() {
    try {
        const result = await dbService.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_name LIKE '%sub%' OR table_name LIKE '%cat%'
            ORDER BY table_name
        `);
        
        console.log('Tables with sub or cat:');
        result.rows.forEach(row => console.log('- ', row.table_name));
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkSubcategoryTable();
