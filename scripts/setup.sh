#!/usr/bin/env bash
# Afghan Go - Setup Script
# Checks prerequisites, installs dependencies, and configures the project

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
    echo "║              Afghan Go - افغان ګو Setup                ║"
    echo "║         Bus Ticket Booking System Installer             ║"
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

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed ($(command -v $1))"
        return 0
    else
        print_error "$1 is NOT installed"
        return 1
    fi
}

check_version() {
    local cmd="$1"
    local min_version="$2"
    local version_output
    version_output=$($cmd --version 2>&1 | head -1)
    echo "$version_output"
}

# Main setup
print_header

ERRORS=0

# ─── Step 1: Check Prerequisites ────────────────────────────────────────────
print_step "Checking prerequisites..."

echo ""
echo "Checking Node.js..."
if check_command node; then
    NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VERSION" -lt 20 ]; then
        print_warning "Node.js version $NODE_VERSION detected. Version 20+ recommended."
    fi
else
    ERRORS=$((ERRORS + 1))
    echo "  Install: https://nodejs.org/ or use nvm"
    echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
    echo "  nvm install 20"
fi

echo ""
echo "Checking npm..."
if check_command npm; then
    NPM_VERSION=$(npm --version)
    print_success "npm $NPM_VERSION"
else
    ERRORS=$((ERRORS + 1))
    echo "  Install: npm comes with Node.js"
fi

echo ""
echo "Checking Flutter..."
if check_command flutter; then
    FLUTTER_VERSION=$(flutter --version 2>&1 | head -1 | awk '{print $2}')
    print_success "Flutter $FLUTTER_VERSION"
else
    print_warning "Flutter is NOT installed (optional for backend-only setup)"
    echo "  Install: https://flutter.dev/docs/get-started/install"
fi

echo ""
echo "Checking PostgreSQL client..."
if check_command psql; then
    PSQL_VERSION=$(psql --version | awk '{print $3}')
    print_success "psql $PSQL_VERSION (client)"
else
    print_warning "PostgreSQL client not found (optional if using Supabase web interface)"
    echo "  Install: sudo apt install postgresql-client"
fi

echo ""
echo "Checking Git..."
if check_command git; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    print_success "git $GIT_VERSION"
else
    ERRORS=$((ERRORS + 1))
    echo "  Install: sudo apt install git"
fi

echo ""
echo "Checking Redis CLI..."
if check_command redis-cli; then
    print_success "redis-cli is installed"
else
    print_warning "Redis CLI not found (optional, needed only for direct Redis debugging)"
fi

# ─── Step 2: Install Backend Dependencies ────────────────────────────────────
print_step "Installing backend dependencies..."

if [ -d "backend" ]; then
    cd backend
    if [ -f "package.json" ]; then
        echo "  Running npm install..."
        npm install
        print_success "Backend dependencies installed"
    else
        print_warning "No package.json found in backend/"
    fi
    cd ..
elif [ -f "package.json" ]; then
    echo "  Running npm install in root..."
    npm install
    print_success "Root dependencies installed"
else
    print_warning "No package.json found. Skipping npm install."
fi

# ─── Step 3: Create .env File ────────────────────────────────────────────────
print_step "Configuring environment..."

if [ -f ".env.example" ]; then
    if [ -f ".env" ]; then
        print_warning ".env file already exists. Skipping creation."
        echo "  Delete .env and re-run setup to create a fresh one."
    else
        cp .env.example .env
        print_success "Created .env from .env.example"
        echo ""
        echo "  ${YELLOW}IMPORTANT:${NC} Edit .env with your actual values:"
        echo "    - SUPABASE_URL"
        echo "    - SUPABASE_SERVICE_ROLE_KEY"
        echo "    - DATABASE_URL"
        echo "    - REDIS_URL"
        echo "    - JWT_SECRET"
        echo "    - HESABPAY_API_KEY"
        echo "    - MOMO_API_KEY"
        echo "    - FIREBASE credentials"
        echo ""
    fi
elif [ -f "backend/.env.example" ]; then
    if [ -f "backend/.env" ]; then
        print_warning "backend/.env already exists. Skipping."
    else
        cp backend/.env.example backend/.env
        print_success "Created backend/.env from backend/.env.example"
        echo "  Edit backend/.env with your actual values."
    fi
else
    print_warning "No .env.example found. Creating template .env..."
    cat > .env << 'EOF'
# Afghan Go - Environment Configuration
# Copy this file to .env and fill in your values

# Server
PORT=3000
NODE_ENV=development
API_VERSION=v1

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Database
DATABASE_URL=postgresql://postgres:password@db.your-project.supabase.co:5432/postgres

# Redis
REDIS_URL=redis://default:password@localhost:6379

# JWT
JWT_SECRET=generate-a-64-char-random-secret
JWT_EXPIRES_IN=7d

# Firebase (Push Notifications)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# Payments
HESABPAY_API_KEY=your-hesabpay-key
HESABPAY_MERCHANT_ID=your-merchant-id
MOMO_API_KEY=your-momo-key
MOMO_MERCHANT_ID=your-momo-merchant-id
PAYPAL_CLIENT_ID=your-paypal-client-id
PAYPAL_CLIENT_SECRET=your-paypal-secret

# SMS
SMS_API_KEY=your-sms-key
SMS_SENDER_ID=AFGOGO

# Frontend
FRONTEND_URL=http://localhost:3000
SUPPORT_EMAIL=support@afghango.app
EOF
    print_success "Created .env template"
    echo "  Edit .env with your actual values."
fi

# ─── Step 4: Create Project Directories ──────────────────────────────────────
print_step "Creating project directories..."

dirs=("logs" "uploads" "temp" "backups")
for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
done
print_success "Project directories created"

# ─── Step 5: Summary ────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
if [ $ERRORS -gt 0 ]; then
    echo -e "${YELLOW}Setup completed with $ERRORS warning(s).${NC}"
    echo "Some prerequisites are missing. Install them and re-run setup."
else
    echo -e "${GREEN}Setup completed successfully!${NC}"
fi

echo ""
echo "Next steps:"
echo "  1. Edit .env with your Supabase, Redis, and payment credentials"
echo "  2. Run: ./scripts/deploy-db.sh <SUPABASE_URL> <SERVICE_ROLE_KEY>"
echo "  3. Run: ./scripts/deploy-backend.sh"
echo "  4. Build Flutter app: cd afghan-go-app && flutter build apk"
echo ""
echo "For development:"
echo "  npm run dev          - Start backend in development mode"
echo "  npm run test         - Run tests"
echo "  npm run lint         - Lint code"
echo ""
echo "Documentation:"
echo "  README.md            - Project overview"
echo "  API.md               - API documentation"
echo "  COST.md              - Cost analysis"
echo ""
