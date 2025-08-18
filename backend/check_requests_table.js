const dbService = require('./services/database');

async function checkRequestsTable() {
    try {
        // Check table structure
        const structure = await dbService.query(`
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'requests' 
            ORDER BY ordinal_position
        `);
        
        console.log('Requests table structure:');
        structure.rows.forEach(row => {
            console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
        });
        
        // Check sample data
        const sample = await dbService.query('SELECT * FROM requests LIMIT 5');
        console.log(`\nSample data (${sample.rows.length} rows):`);
        if (sample.rows.length > 0) {
            console.log(JSON.stringify(sample.rows[0], null, 2));
        }
        
        // Check total count
        const count = await dbService.query('SELECT COUNT(*) as total FROM requests');
        console.log(`\nTotal requests: ${count.rows[0].total}`);
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkRequestsTable();
