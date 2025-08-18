const dbService = require('./services/database');

async function checkTables() {
    try {
        const result = await dbService.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name
        `);
        
        console.log('Available tables:');
        result.rows.forEach(row => console.log('- ', row.table_name));
        
        // Check specifically for request-related tables
        const requestTables = result.rows.filter(row => 
            row.table_name.includes('request') || 
            row.table_name.includes('price')
        );
        
        console.log('\nRequest-related tables:');
        requestTables.forEach(row => console.log('- ', row.table_name));
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkTables();
