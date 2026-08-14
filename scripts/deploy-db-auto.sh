#!/usr/bin/env bash
# Afghan Go - Automated Database Deployment
# Uses direct PostgreSQL connection via Node.js pg driver

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

NODE_BIN="/tmp/opencode/node-v20.11.1-linux-x64/bin/node"
NPM_BIN="/tmp/opencode/node-v20.11.1-linux-x64/bin/npm"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║        Afghan Go - Database Auto-Deployment             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Check Node.js ───────────────────────────────────────────────────────────
if [ ! -f "$NODE_BIN" ]; then
    echo -e "${RED}[ERROR]${NC} Node.js not found at $NODE_BIN"
    exit 1
fi
echo -e "${GREEN}[OK]${NC} Node.js found"

# ─── Install pg package ──────────────────────────────────────────────────────
echo -e "${BLUE}[STEP]${NC} Installing PostgreSQL driver..."
cd /tmp/opencode
PATH="/tmp/opencode/node-v20.11.1-linux-x64/bin:$PATH" npm install pg --silent 2>/dev/null
echo -e "${GREEN}[OK]${NC} pg driver ready"

# ─── Get Database URL ────────────────────────────────────────────────────────
DB_URL="${1:-}"

if [ -z "$DB_URL" ]; then
    echo ""
    echo -e "${YELLOW}To get your Database URL:${NC}"
    echo "  1. Go to https://supabase.com/dashboard"
    echo "  2. Select your project: otucehrhxzeihxoqwzah"
    echo "  3. Go to Settings → Database"
    echo "  4. Scroll to 'Connection string' → 'URI'"
    echo "  5. Copy the full URI (starts with postgresql://...)"
    echo "  6. Uncheck 'Use connection pooler' for direct connection"
    echo ""
    echo -e "${BLUE}Paste your database URL:${NC}"
    read -r DB_URL
fi

if [ -z "$DB_URL" ]; then
    echo -e "${RED}[ERROR]${NC} No database URL provided"
    exit 1
fi

# ─── Read Schema ─────────────────────────────────────────────────────────────
SCHEMA_FILE="../database/schema.sql"
if [ ! -f "$SCHEMA_FILE" ]; then
    # Try relative to script location
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SCHEMA_FILE="${SCRIPT_DIR}/../database/schema.sql"
fi

if [ ! -f "$SCHEMA_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Schema file not found at $SCHEMA_FILE"
    exit 1
fi

echo -e "${BLUE}[STEP]${NC} Schema file found: $SCHEMA_FILE"

# ─── Create Deployment Script ────────────────────────────────────────────────
DEPLOY_SCRIPT=$(cat << 'NODEEOF'
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function deploy() {
    const dbUrl = process.argv[2];
    const schemaFile = process.argv[3];
    
    if (!dbUrl || !schemaFile) {
        console.error('Usage: node deploy.js <DB_URL> <SCHEMA_FILE>');
        process.exit(1);
    }
    
    const client = new Client({
        connectionString: dbUrl,
        ssl: { rejectUnauthorized: false }
    });
    
    try {
        console.log('Connecting to database...');
        await client.connect();
        console.log('Connected successfully!');
        
        console.log('Reading schema file...');
        const sql = fs.readFileSync(schemaFile, 'utf8');
        
        // Split by semicolons but handle $$ blocks properly
        console.log('Executing schema...');
        
        // Execute the entire SQL as one block
        try {
            await client.query(sql);
            console.log('Schema executed successfully!');
        } catch (err) {
            // If full block fails, try statement by statement
            console.log('Full block failed, trying statement by statement...');
            
            // Simple splitter that respects $$ blocks
            const statements = [];
            let current = '';
            let inDollarQuote = false;
            
            for (let i = 0; i < sql.length; i++) {
                current += sql[i];
                
                if (sql.substring(i, i+2) === '$$') {
                    inDollarQuote = !inDollarQuote;
                }
                
                if (sql[i] === ';' && !inDollarQuote) {
                    const trimmed = current.trim();
                    if (trimmed && !trimmed.startsWith('--')) {
                        statements.push(trimmed);
                    }
                    current = '';
                }
            }
            
            let success = 0;
            let failed = 0;
            
            for (const stmt of statements) {
                try {
                    await client.query(stmt);
                    success++;
                } catch (err) {
                    if (err.code === '42710' || err.code === '42P07' || err.code === '23505') {
                        // Type already exists, table already exists - skip
                        success++;
                    } else {
                        console.error(`Failed: ${stmt.substring(0, 80)}...`);
                        console.error(`  Error: ${err.message}`);
                        failed++;
                    }
                }
            }
            
            console.log(`\nResults: ${success} succeeded, ${failed} failed`);
        }
        
        // Verify tables
        console.log('\nVerifying tables...');
        const tables = [
            'users', 'transport_companies', 'buses', 'trips',
            'seat_locks', 'bookings', 'payments', 'reviews', 'notifications'
        ];
        
        for (const table of tables) {
            try {
                const res = await client.query(
                    "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = $1)",
                    [table]
                );
                if (res.rows[0].exists) {
                    console.log(`  ✓ ${table}`);
                } else {
                    console.log(`  ✗ ${table} (not found)`);
                }
            } catch (err) {
                console.log(`  ? ${table} (check failed)`);
            }
        }
        
        console.log('\nDeployment complete!');
    } catch (err) {
        console.error('Deployment failed:', err.message);
        process.exit(1);
    } finally {
        await client.end();
    }
}

deploy();
NODEEOF
)

DEPLOY_JS="/tmp/opencode/deploy_db.js"
echo "$DEPLOY_SCRIPT" > "$DEPLOY_JS"

# ─── Run Deployment ──────────────────────────────────────────────────────────
echo -e "${BLUE}[STEP]${NC} Deploying schema to Supabase..."
echo ""

ABSOLUTE_SCHEMA="$(cd "$(dirname "$SCHEMA_FILE")" && pwd)/$(basename "$SCHEMA_FILE")"
"$NODE_BIN" "$DEPLOY_JS" "$DB_URL" "$ABSOLUTE_SCHEMA"

EXIT_CODE=$?

rm -f "$DEPLOY_JS"

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Database deployment completed successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
else
    echo ""
    echo -e "${RED}Deployment failed. Check errors above.${NC}"
    exit 1
fi
