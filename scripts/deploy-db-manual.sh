#!/usr/bin/env bash
# Afghan Go - Manual Database Deployment
# Provides SQL for copy-paste into Supabase Dashboard SQL Editor

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Afghan Go - Manual Database Deployment              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Find schema file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/../database/schema.sql"

if [ ! -f "$SCHEMA_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Schema file not found at $SCHEMA_FILE"
    exit 1
fi

echo -e "${BLUE}[INSTRUCTIONS]${NC}"
echo ""
echo "Follow these steps to deploy the database:"
echo ""
echo "  1. Open your browser and go to:"
echo "     ${GREEN}https://supabase.com/dashboard${NC}"
echo ""
echo "  2. Select your project: ${GREEN}otucehrhxzeihxoqwzah${NC}"
echo ""
echo "  3. In the left sidebar, click: ${GREEN}SQL Editor${NC}"
echo ""
echo "  4. Click ${GREEN}\"New query\"${NC} button"
echo ""
echo "  5. Copy the ENTIRE SQL content below and paste it"
echo ""
echo "  6. Click ${GREEN}\"Run\"${NC} button (or press Ctrl+Enter)"
echo ""
echo "  7. Verify all tables were created (see verification below)"
echo ""

echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  COPY EVERYTHING BETWEEN THE DASHES BELOW                 ${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo ""
cat "$SCHEMA_FILE"
echo ""
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  END OF SQL CONTENT                                       ${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}[VERIFICATION]${NC}"
echo ""
echo "After running the SQL, verify these tables exist:"
echo ""
TABLES=("users" "transport_companies" "buses" "trips" "seat_locks" "bookings" "payments" "reviews" "notifications")
for table in "${TABLES[@]}"; do
    echo "  ✓ $table"
done
echo ""
echo "Also verify these cities were seeded:"
CITIES=("Kabul" "Herat" "Mazar-i-Sharif" "Kandahar" "Jalalabad" "Kunduz" "Bamyan" "Lashkar Gah" "Gardez" "Taloqan" "Sheberghan" "Pul-e-Khumri" "Mehtarlam" "Panjshir")
for city in "${CITIES[@]}"; do
    echo "  ✓ $city"
done
echo ""

echo -e "${GREEN}[SUCCESS]${NC} SQL content displayed above."
echo ""
echo "Next step: Run ./deploy-backend.sh"
echo ""
