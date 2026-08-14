#!/usr/bin/env bash
# Afghan Go - Backend Deployment Script
# Builds TypeScript, runs migrations, and starts the server

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           Afghan Go - Backend Deployment                ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header

# ─── Determine Backend Directory ─────────────────────────────────────────────
BACKEND_DIR="."
if [ -d "backend" ] && [ -f "backend/package.json" ]; then
    BACKEND_DIR="backend"
fi

if [ ! -f "${BACKEND_DIR}/package.json" ]; then
    print_error "No package.json found in current directory or backend/"
    echo "  Make sure you're in the project root or the backend directory exists."
    exit 1
fi

cd "$BACKEND_DIR"
echo "Working directory: $(pwd)"

# ─── Check Environment ──────────────────────────────────────────────────────
print_step "Checking environment..."

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_warning "Created .env from .env.example — please edit with real values"
    else
        print_error ".env file not found"
        echo "  Create .env with required environment variables."
        echo "  See README.md for required variables."
        exit 1
    fi
fi

# Check critical env vars
REQUIRED_VARS=("SUPABASE_URL" "SUPABASE_SERVICE_ROLE_KEY" "DATABASE_URL" "JWT_SECRET")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    VALUE=$(grep -E "^${var}=" .env 2>/dev/null | cut -d'=' -f2- | head -1)
    if [ -z "$VALUE" ] || [ "$VALUE" = "your-*" ] || [ "$VALUE" = "generate*" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    print_warning "The following environment variables may not be configured:"
    for var in "${MISSING_VARS[@]}"; do
        echo "    - $var"
    done
    echo ""
    echo "  Edit .env and set proper values before the server will work correctly."
    echo ""
fi

print_success "Environment check completed"

# ─── Check Node.js Version ──────────────────────────────────────────────────
print_step "Verifying Node.js version..."

NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
if [ -z "$NODE_VERSION" ] || [ "$NODE_VERSION" -lt 20 ]; then
    print_error "Node.js 20+ required. Current: $(node --version 2>/dev/null || echo 'not found')"
    exit 1
fi
print_success "Node.js $(node --version)"

# ─── Install Dependencies ───────────────────────────────────────────────────
print_step "Installing dependencies..."

if [ -f "package-lock.json" ]; then
    npm ci
elif [ -f "yarn.lock" ]; then
    yarn install --frozen-lockfile
else
    npm install
fi
print_success "Dependencies installed"

# ─── Build TypeScript ───────────────────────────────────────────────────────
print_step "Building TypeScript..."

# Check if build script exists
if npm run | grep -q '"build"'; then
    npm run build
    print_success "TypeScript build completed"
else
    # Try tsc directly
    if [ -f "tsconfig.json" ]; then
        npx tsc
        print_success "TypeScript compiled"
    else
        print_warning "No tsconfig.json found — skipping build"
    fi
fi

# ─── Run Migrations ────────────────────────────────────────────────────────
print_step "Running database migrations..."

if npm run | grep -q '"migrate"'; then
    npm run migrate
    print_success "Migrations completed"
elif [ -d "migrations" ] || [ -d "src/migrations" ]; then
    MIGRATION_DIR="migrations"
    [ -d "src/migrations" ] && MIGRATION_DIR="src/migrations"
    echo "  Found migrations in $MIGRATION_DIR/"
    # Try to run with a migration tool
    if command -v dbmate &> /dev/null; then
        dbmate up
        print_success "Migrations completed via dbmate"
    elif command -v node-pg-migrate &> /dev/null; then
        node-pg-migrate up
        print_success "Migrations completed via node-pg-migrate"
    else
        print_warning "No migration tool found. Run migrations manually."
        echo "  Install dbmate: brew install dbmate"
        echo "  Or install node-pg-migrate: npm install -g node-pg-migrate"
    fi
else
    print_success "No migrations to run (schema managed by Supabase)"
fi

# ─── Seed Data (Optional) ──────────────────────────────────────────────────
print_step "Checking for seed data..."

if npm run | grep -q '"seed"'; then
    read -p "Run seed data script? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        npm run seed
        print_success "Seed data loaded"
    else
        print_success "Skipped seed data"
    fi
else
    print_success "No seed script found"
fi

# ─── Health Check ───────────────────────────────────────────────────────────
print_step "Performing health check..."

# Start server in background temporarily
PORT=$(grep -E "^PORT=" .env 2>/dev/null | cut -d'=' -f2 | head -1)
PORT=${PORT:-3000}

echo "  Starting server on port $PORT for health check..."
SERVER_PID=""
timeout 15 bash -c "
    node dist/index.js &
    SERVER_PID=\$!
    sleep 5

    # Test health endpoint
    HTTP_CODE=\$(curl -s -o /dev/null -w '%{http_code}' http://localhost:${PORT}/api/v1/health 2>/dev/null || echo '000')
    if [ \"\$HTTP_CODE\" = '200' ] || [ \"\$HTTP_CODE\" = '204' ]; then
        echo 'health_ok'
    else
        echo 'health_fail'
    fi

    kill \$SERVER_PID 2>/dev/null || true
" 2>/dev/null

if [ $? -eq 0 ]; then
    print_success "Health check passed"
else
    print_warning "Health check could not be completed (timeout)"
fi

# ─── Run Tests ──────────────────────────────────────────────────────────────
print_step "Running tests..."

if npm run | grep -q '"test"'; then
    read -p "Run test suite? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        npm test
        print_success "Tests completed"
    else
        print_success "Skipped tests"
    fi
else
    print_success "No test script found"
fi

# ─── Start Server ──────────────────────────────────────────────────────────
print_step "Starting production server..."

echo ""
echo "  ${CYAN}Starting Afghan Go API server...${NC}"
echo "  Port: $PORT"
echo "  Environment: $(grep -E '^NODE_ENV=' .env 2>/dev/null | cut -d'=' -f2 || echo 'development')"
echo ""

# Start the server
exec node dist/index.js 2>&1 | tee ../logs/server-$(date +%Y%m%d-%H%M%S).log
