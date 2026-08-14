const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const SCHEMA_FILE = path.join(__dirname, '..', 'database', 'schema.sql');

async function deploy() {
    // Supabase connection pooler (Transaction mode - port 6543)
    // Format: postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres
    const DB_URL = process.env.DATABASE_URL;
    
    if (!DB_URL) {
        console.log('');
        console.log('╔══════════════════════════════════════════════════════════╗');
        console.log('║  Need Database URL for direct connection                ║');
        console.log('╚══════════════════════════════════════════════════════════╝');
        console.log('');
        console.log('To get your Database URL:');
        console.log('  1. Go to https://supabase.com/dashboard');
        console.log('  2. Select project: otucehrhxzeihxoqwzah');
        console.log('  3. Go to Settings → Database');
        console.log('  4. Under "Connection string", select "URI" tab');
        console.log('  5. Copy the full URI');
        console.log('  6. IMPORTANT: UNCHECK "Use connection pooler"');
        console.log('     (use direct connection on port 5432)');
        console.log('');
        console.log('Then run:');
        console.log('  DATABASE_URL="postgresql://..." node deploy_direct.js');
        console.log('');
        console.log('Or paste the SQL manually in Supabase Dashboard → SQL Editor');
        console.log('');
        
        // Show the SQL for manual copy
        if (fs.existsSync(SCHEMA_FILE)) {
            console.log('═'.repeat(60));
            console.log('  COPY THE SQL BELOW INTO SUPABASE SQL EDITOR');
            console.log('═'.repeat(60));
            console.log('');
            console.log(fs.readFileSync(SCHEMA_FILE, 'utf8'));
            console.log('');
            console.log('═'.repeat(60));
            console.log('  END OF SQL');
            console.log('═'.repeat(60));
        }
        process.exit(0);
    }

    console.log('Connecting to database...');
    
    const client = new Client({
        connectionString: DB_URL,
        ssl: { rejectUnauthorized: false }
    });

    try {
        await client.connect();
        console.log('Connected successfully!');

        console.log('Reading schema file...');
        const sql = fs.readFileSync(SCHEMA_FILE, 'utf8');
        console.log(`Schema size: ${(sql.length / 1024).toFixed(1)} KB`);

        console.log('Executing schema...');
        
        // Try executing the entire SQL as one transaction
        try {
            await client.query('BEGIN');
            await client.query(sql);
            await client.query('COMMIT');
            console.log('Schema executed successfully in single transaction!');
        } catch (err) {
            await client.query('ROLLBACK').catch(() => {});
            
            if (err.code === '42710') {
                console.log('Types already exist, trying without transaction...');
            } else {
                console.log(`Transaction failed: ${err.message}`);
                console.log('Trying statement by statement...');
            }
            
            // Split and execute individually
            const statements = [];
            let current = '';
            let inDollarQuote = false;
            
            for (let i = 0; i < sql.length; i++) {
                current += sql[i];
                
                if (sql.substring(i, i + 2) === '$$') {
                    inDollarQuote = !inDollarQuote;
                }
                
                if (sql[i] === ';' && !inDollarQuote) {
                    const trimmed = current.trim();
                    if (trimmed && !trimmed.startsWith('--') && trimmed !== '') {
                        statements.push(trimmed);
                    }
                    current = '';
                }
            }
            
            let success = 0;
            let skipped = 0;
            let failed = 0;
            
            for (const stmt of statements) {
                try {
                    await client.query(stmt);
                    success++;
                } catch (err) {
                    if (err.code === '42710' || err.code === '42P07' || 
                        err.code === '23505' || err.code === '42P16' ||
                        err.message.includes('already exists')) {
                        skipped++;
                    } else {
                        console.error(`\nFailed statement: ${stmt.substring(0, 100)}...`);
                        console.error(`  Error: ${err.message}`);
                        failed++;
                    }
                }
            }
            
            console.log(`\nResults: ${success} executed, ${skipped} skipped (already exist), ${failed} failed`);
        }

        // Verify tables
        console.log('\n--- Verifying Tables ---');
        const tables = [
            'users', 'transport_companies', 'buses', 'trips',
            'seat_locks', 'bookings', 'payments', 'reviews', 'notifications'
        ];
        
        let allGood = true;
        for (const table of tables) {
            try {
                const res = await client.query(
                    "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = $1)",
                    [table]
                );
                if (res.rows[0].exists) {
                    const count = await client.query(`SELECT COUNT(*) FROM ${table}`);
                    console.log(`  ✓ ${table} (${count.rows[0].count} rows)`);
                } else {
                    console.log(`  ✗ ${table} NOT FOUND`);
                    allGood = false;
                }
            } catch (err) {
                console.log(`  ? ${table} (error: ${err.message})`);
                allGood = false;
            }
        }

        // Check cities
        console.log('\n--- Verifying Seed Data ---');
        try {
            const cities = await client.query('SELECT COUNT(*) FROM cities');
            console.log(`  ✓ Cities: ${cities.rows[0].count}`);
        } catch {
            console.log('  ? Cities table not found');
        }

        console.log('');
        if (allGood) {
            console.log('══════════════════════════════════════════════════════════');
            console.log('  DATABASE DEPLOYED SUCCESSFULLY!');
            console.log('══════════════════════════════════════════════════════════');
        } else {
            console.log('⚠ Some tables may be missing. Check errors above.');
        }
        
    } catch (err) {
        console.error('Connection failed:', err.message);
        console.error('');
        console.error('Make sure you are using the DIRECT connection URL (port 5432),');
        console.error('not the pooler URL (port 6543).');
        process.exit(1);
    } finally {
        await client.end();
    }
}

deploy();
