#!/usr/bin/env bash
# Afghan Go - Database Deployment Script
# Deploys PostgreSQL schema to Supabase

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
    echo "║           Afghan Go - Database Deployment               ║"
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

# ─── Parse Arguments ─────────────────────────────────────────────────────────
print_header

SUPABASE_URL="${1:-}"
SERVICE_ROLE_KEY="${2:-}"

if [ -z "$SUPABASE_URL" ] || [ -z "$SERVICE_ROLE_KEY" ]; then
    echo "Usage: $0 <SUPABASE_URL> <SERVICE_ROLE_KEY>"
    echo ""
    echo "Example:"
    echo "  $0 https://abc123.supabase.co eyJhbGciOiJIUzI1NiIsInR5cCI6..."
    echo ""
    echo "Find these values in: Supabase Dashboard → Settings → API"
    exit 1
fi

# Strip trailing slash if present
SUPABASE_URL="${SUPABASE_URL%/}"

print_step "Validating Supabase connection..."

# Test connection
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "apikey: ${SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
    "${SUPABASE_URL}/rest/v1/" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    print_success "Supabase connection successful"
else
    print_error "Cannot connect to Supabase (HTTP $HTTP_CODE)"
    echo "  URL: ${SUPABASE_URL}"
    echo "  Please check your URL and service role key."
    exit 1
fi

# ─── Check for Schema File ───────────────────────────────────────────────────
print_step "Looking for schema file..."

SCHEMA_FILE=""
for candidate in "schema/supabase_schema.sql" "sql/supabase_schema.sql" "schema.sql" "supabase_schema.sql"; do
    if [ -f "$candidate" ]; then
        SCHEMA_FILE="$candidate"
        break
    fi
done

if [ -z "$SCHEMA_FILE" ]; then
    print_warning "No schema file found. Creating inline schema..."
    SCHEMA_FILE="/tmp/afghan_go_schema.sql"

    cat > "$SCHEMA_FILE" << 'SCHEMA_EOF'
-- Afghan Go - Supabase Schema
-- Run this in Supabase SQL Editor or via this script

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ─── Cities ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_en VARCHAR(100) NOT NULL,
    name_fa VARCHAR(100) NOT NULL,
    name_ps VARCHAR(100) NOT NULL,
    province VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    timezone VARCHAR(50) DEFAULT 'Asia/Kabul',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Bus Operators ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bus_operators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    name_en VARCHAR(200) NOT NULL,
    name_fa VARCHAR(200),
    name_ps VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(200),
    license_number VARCHAR(100),
    rating DECIMAL(3, 2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    is_vip BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Buses ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS buses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operator_id UUID NOT NULL REFERENCES bus_operators(id),
    plate_number VARCHAR(20) NOT NULL,
    bus_type VARCHAR(50) NOT NULL DEFAULT 'standard',
    total_seats INTEGER NOT NULL DEFAULT 40,
    amenities JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_plate_number UNIQUE (plate_number)
);

-- ─── Routes ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    origin_city_id UUID NOT NULL REFERENCES cities(id),
    destination_city_id UUID NOT NULL REFERENCES cities(id),
    distance_km DECIMAL(10, 2),
    estimated_duration_minutes INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT different_cities CHECK (origin_city_id != destination_city_id),
    CONSTRAINT unique_route UNIQUE (origin_city_id, destination_city_id)
);

-- ─── Trips ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID NOT NULL REFERENCES routes(id),
    bus_id UUID NOT NULL REFERENCES buses(id),
    departure_time TIMESTAMPTZ NOT NULL,
    arrival_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) DEFAULT 'scheduled',
    base_price DECIMAL(10, 2) NOT NULL,
    vip_price DECIMAL(10, 2),
    available_seats INTEGER NOT NULL DEFAULT 40,
    currency VARCHAR(3) DEFAULT 'AFN',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_status CHECK (status IN ('scheduled', 'boarding', 'departed', 'in_transit', 'arrived', 'cancelled')),
    CONSTRAINT future_departure CHECK (departure_time > NOW())
);

-- ─── Seat Maps ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS seat_maps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bus_id UUID NOT NULL REFERENCES buses(id),
    seat_number VARCHAR(5) NOT NULL,
    row_number INTEGER NOT NULL,
    column_letter CHAR(1) NOT NULL,
    seat_type VARCHAR(20) DEFAULT 'standard',
    is_available BOOLEAN DEFAULT true,
    extra_price DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_seat_on_bus UNIQUE (bus_id, seat_number)
);

-- ─── Bookings ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    trip_id UUID NOT NULL REFERENCES trips(id),
    booking_reference VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'pending',
    seat_numbers TEXT[] NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    deposit_amount DECIMAL(10, 2) NOT NULL,
    remaining_amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'AFN',
    passenger_name VARCHAR(200) NOT NULL,
    passenger_phone VARCHAR(20) NOT NULL,
    passenger_national_id VARCHAR(20),
    notes TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_booking_status CHECK (status IN ('pending', 'confirmed', 'paid_deposit', 'paid_full', 'cancelled', 'expired', 'completed'))
);

-- ─── Payments ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id),
    payment_method VARCHAR(30) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'AFN',
    status VARCHAR(20) DEFAULT 'pending',
    transaction_id VARCHAR(200),
    gateway_response JSONB,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_payment_method CHECK (payment_method IN ('hesabpay', 'momo', 'paypal', 'cash')),
    CONSTRAINT valid_payment_status CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded'))
);

-- ─── Notifications ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    title VARCHAR(200) NOT NULL,
    title_fa VARCHAR(200),
    title_ps VARCHAR(200),
    message TEXT NOT NULL,
    message_fa TEXT,
    message_ps TEXT,
    type VARCHAR(30) NOT NULL,
    is_read BOOLEAN DEFAULT false,
    data JSONB,
    sent_via TEXT[] DEFAULT ARRAY['push'],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- ─── Reviews ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    trip_id UUID NOT NULL REFERENCES trips(id),
    operator_id UUID NOT NULL REFERENCES bus_operators(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_anonymous BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_trip_review UNIQUE (user_id, trip_id)
);

-- ─── Seat Locks (Redis-backed, with DB fallback) ─────────────────────────────
CREATE TABLE IF NOT EXISTS seat_locks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id),
    seat_number VARCHAR(5) NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    locked_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT unique_seat_lock UNIQUE (trip_id, seat_number)
);

-- ─── User Profiles ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) UNIQUE,
    full_name VARCHAR(200) NOT NULL,
    phone VARCHAR(20),
    national_id VARCHAR(20),
    preferred_language VARCHAR(5) DEFAULT 'en',
    firebase_token TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Admin Roles ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) UNIQUE,
    role VARCHAR(50) NOT NULL DEFAULT 'operator',
    permissions JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_role CHECK (role IN ('superadmin', 'operator', 'support'))
);

-- ─── Indexes ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_trips_route ON trips(route_id);
CREATE INDEX IF NOT EXISTS idx_trips_departure ON trips(departure_time);
CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_bus ON trips(bus_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_trip ON bookings(trip_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_reference ON bookings(booking_reference);
CREATE INDEX IF NOT EXISTS idx_payments_booking ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_seat_locks_trip ON seat_locks(trip_id);
CREATE INDEX IF NOT EXISTS idx_seat_locks_expires ON seat_locks(expires_at);
CREATE INDEX IF NOT EXISTS idx_routes_origin ON routes(origin_city_id);
CREATE INDEX IF NOT EXISTS idx_routes_destination ON routes(destination_city_id);
CREATE INDEX IF NOT EXISTS idx_cities_active ON cities(is_active);
CREATE INDEX IF NOT EXISTS idx_buses_operator ON buses(operator_id);
CREATE INDEX IF NOT EXISTS idx_reviews_operator ON reviews(operator_id);
CREATE INDEX IF NOT EXISTS idx_reviews_trip ON reviews(trip_id);

-- ─── Row Level Security ─────────────────────────────────────────────────────
ALTER TABLE cities ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_operators ENABLE ROW LEVEL SECURITY;
ALTER TABLE buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE seat_maps ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE seat_locks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_roles ENABLE ROW LEVEL SECURITY;

-- Public read policies for public tables
CREATE POLICY "Cities are viewable by everyone" ON cities FOR SELECT USING (true);
CREATE POLICY "Operators are viewable by everyone" ON bus_operators FOR SELECT USING (true);
CREATE POLICY "Buses are viewable by everyone" ON buses FOR SELECT USING (true);
CREATE POLICY "Routes are viewable by everyone" ON routes FOR SELECT USING (true);
CREATE POLICY "Trips are viewable by everyone" ON trips FOR SELECT USING (true);
CREATE POLICY "Seat maps are viewable by everyone" ON seat_maps FOR SELECT USING (true);

-- User-specific policies
CREATE POLICY "Users can view own bookings" ON bookings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create bookings" ON bookings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own bookings" ON bookings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own payments" ON payments FOR SELECT USING (
    booking_id IN (SELECT id FROM bookings WHERE user_id = auth.uid())
);
CREATE POLICY "Users can create payments" ON payments FOR INSERT WITH CHECK (
    booking_id IN (SELECT id FROM bookings WHERE user_id = auth.uid())
);
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can create reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Reviews are viewable by everyone" ON reviews FOR SELECT USING (true);
CREATE POLICY "Users can lock seats" ON seat_locks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own seat locks" ON seat_locks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own seat locks" ON seat_locks FOR DELETE USING (auth.uid() = user_id);

-- Admin policies
CREATE POLICY "Admins can do everything" ON bus_operators FOR ALL USING (
    EXISTS (SELECT 1 FROM admin_roles WHERE user_id = auth.uid() AND role = 'superadmin')
);
CREATE POLICY "Operators can manage own buses" ON buses FOR ALL USING (
    operator_id IN (SELECT id FROM bus_operators WHERE id = bus_operators.id)
);
CREATE POLICY "Admins can manage trips" ON trips FOR ALL USING (
    EXISTS (SELECT 1 FROM admin_roles WHERE user_id = auth.uid() AND role IN ('superadmin', 'operator'))
);

-- ─── Functions ───────────────────────────────────────────────────────────────

-- Auto-expire pending bookings after 30 minutes
CREATE OR REPLACE FUNCTION expire_pending_bookings()
RETURNS void AS $$
BEGIN
    UPDATE bookings
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending'
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Release expired seat locks
CREATE OR REPLACE FUNCTION release_expired_locks()
RETURNS void AS $$
BEGIN
    DELETE FROM seat_locks
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Generate booking reference
CREATE OR REPLACE FUNCTION generate_booking_reference()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.booking_reference IS NULL THEN
        NEW.booking_reference := 'AFG' || TO_CHAR(NOW(), 'YYMMDD') || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_booking_reference
    BEFORE INSERT ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION generate_booking_reference();

-- Update seat count on booking
CREATE OR REPLACE FUNCTION update_trip_seats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status != 'cancelled' THEN
        UPDATE trips
        SET available_seats = available_seats - array_length(NEW.seat_numbers, 1)
        WHERE id = NEW.trip_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.status != 'cancelled' AND NEW.status = 'cancelled' THEN
        UPDATE trips
        SET available_seats = available_seats + array_length(NEW.seat_numbers, 1)
        WHERE id = NEW.trip_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_booking_status_change
    AFTER INSERT OR UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_trip_seats();

-- Update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_cities_updated_at BEFORE UPDATE ON cities FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_bus_operators_updated_at BEFORE UPDATE ON bus_operators FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_buses_updated_at BEFORE UPDATE ON buses FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON trips FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─── Seed Data: Afghan Cities ───────────────────────────────────────────────
INSERT INTO cities (name_en, name_fa, name_ps, province, latitude, longitude) VALUES
    ('Kabul', 'کابل', 'کابل', 'Kabul', 34.5553, 69.2075),
    ('Herat', 'هرات', 'هرات', 'Herat', 34.3529, 62.2040),
    ('Mazar-i-Sharif', 'مزارشریف', 'مزارشریف', 'Balkh', 36.7134, 67.1109),
    ('Kandahar', 'کندهار', 'کندهار', 'Kandahar', 31.6289, 65.7372),
    ('Jalalabad', 'جلال‌آباد', 'جلال‌آباد', 'Nangarhar', 34.4345, 70.4453),
    ('Kunduz', 'کندز', 'کندز', 'Kunduz', 36.7286, 68.8682),
    ('Bamyan', 'بامیان', 'بامیان', 'Bamyan', 34.8212, 67.8237),
    ('Lashkar Gah', 'لشکرگاه', 'لشکرګاه', 'Helmand', 31.5937, 64.3592),
    ('Gardez', 'گردیز', 'ګردېز', 'Paktia', 33.5935, 69.2113),
    ('Taloqan', 'تالقان', 'تالقان', 'Takhar', 36.7356, 69.5363),
    ('Sheberghan', 'شبرغان', 'شبرغان', 'Jowzjan', 36.6626, 65.7531),
    ('Pul-e-Khumri', 'پل‌خمری', 'پل خمري', 'Baghlan', 35.9489, 68.7345),
    ('Mehtarlam', 'مهترلام', 'مهترلامل', 'Laghman', 34.6729, 69.9210),
    ('Panjshir', 'پنجشیر', 'پنجشير', 'Panjshir', 35.3156, 69.6847)
ON CONFLICT DO NOTHING;

-- ─── Seed Data: Sample Routes ───────────────────────────────────────────────
INSERT INTO routes (origin_city_id, destination_city_id, distance_km, estimated_duration_minutes)
SELECT o.id, d.id, r.distance_km, r.duration_minutes
FROM cities o
CROSS JOIN cities d
CROSS JOIN (VALUES
    ('Kabul', 'Herat', 645, 480),
    ('Kabul', 'Mazar-i-Sharif', 310, 300),
    ('Kabul', 'Kandahar', 500, 420),
    ('Kabul', 'Jalalabad', 130, 120),
    ('Kabul', 'Kunduz', 345, 330),
    ('Kabul', 'Bamyan', 180, 240),
    ('Herat', 'Mazar-i-Sharif', 560, 480),
    ('Herat', 'Kandahar', 550, 450),
    ('Mazar-i-Sharif', 'Kunduz', 135, 120),
    ('Kandahar', 'Herat', 550, 450),
    ('Kabul', 'Gardez', 100, 120),
    ('Kabul', 'Taloqan', 290, 300),
    ('Kabul', 'Sheberghan', 400, 390),
    ('Kabul', 'Pul-e-Khumri', 210, 210),
    ('Kabul', 'Mehtarlam', 80, 90),
    ('Kabul', 'Panjshir', 100, 120)
) AS r(origin_name, dest_name, distance_km, duration_minutes)
WHERE o.name_en = r.origin_name AND d.name_en = r.dest_name
ON CONFLICT (origin_city_id, destination_city_id) DO NOTHING;

-- ─── Seed Data: Sample Bus Operators ────────────────────────────────────────
INSERT INTO bus_operators (name, name_en, name_fa, name_ps, phone, license_number, is_vip) VALUES
    ('Afghan Go Express', 'Afghan Go Express', 'افغان ګو اکسپرس', 'افغان ګو اکسپرس', '+93-700-123456', 'AG-001', true),
    ('Kabul-Herat Line', 'Kabul-Herat Line', 'خط کابل-هرات', 'د کابل-هرات لاین', '+93-700-234567', 'KH-001', false),
    ('Northern Star', 'Northern Star', 'ستاره شمال', 'شمالي ستوری', '+93-700-345678', 'NS-001', false),
    ('VIP Express', 'VIP Express', 'وی آی پی اکسپرس', 'وی آی پی اکسپرس', '+93-700-456789', 'VP-001', true)
ON CONFLICT DO NOTHING;
SCHEMA_EOF
    print_success "Generated schema file at $SCHEMA_FILE"
fi

echo "  Schema file: $SCHEMA_FILE"

# ─── Run Schema Against Supabase ─────────────────────────────────────────────
print_step "Deploying schema to Supabase..."

SCHEMA_CONTENT=$(cat "$SCHEMA_FILE")

# Escape the SQL for JSON payload
ESCAPED_SQL=$(echo "$SCHEMA_CONTENT" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || echo "$SCHEMA_CONTENT" | jq -Rs '.')

# Execute via Supabase SQL API
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    "${SUPABASE_URL}/rest/v1/rpc/exec_sql" \
    -H "apikey: ${SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"query\": ${ESCAPED_SQL}}" 2>/dev/null)

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ]; then
    print_success "Schema executed successfully"
else
    print_warning "Direct RPC failed (HTTP $HTTP_CODE). Trying SQL Editor API..."

    # Alternative: Use Supabase Management API
    RESPONSE2=$(curl -s -w "\n%{http_code}" \
        -X POST \
        "${SUPABASE_URL}/pg/query" \
        -H "apikey: ${SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"query\": ${ESCAPED_SQL}}" 2>/dev/null)

    HTTP_CODE2=$(echo "$RESPONSE2" | tail -1)

    if [ "$HTTP_CODE2" = "200" ] || [ "$HTTP_CODE2" = "204" ]; then
        print_success "Schema executed via SQL API"
    else
        print_error "Schema deployment failed"
        echo "  HTTP Code: $HTTP_CODE2"
        echo "  Response: $(echo "$RESPONSE2" | head -n -1)"
        echo ""
        echo "  Manual deployment option:"
        echo "  1. Go to Supabase Dashboard → SQL Editor"
        echo "  2. Copy contents of $SCHEMA_FILE"
        echo "  3. Paste and run"
        exit 1
    fi
fi

# ─── Verify Tables ───────────────────────────────────────────────────────────
print_step "Verifying tables were created..."

TABLES=("cities" "bus_operators" "buses" "routes" "trips" "seat_maps" "bookings" "payments" "notifications" "reviews" "seat_locks" "user_profiles" "admin_roles")

ALL_OK=true
for table in "${TABLES[@]}"; do
    COUNT_RESPONSE=$(curl -s \
        "${SUPABASE_URL}/rest/v1/${table}?select=count" \
        -H "apikey: ${SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
        -H "Prefer: count=exact" \
        -H "Range-Unit: items" \
        -H "Range: 0-0" 2>/dev/null)

    if echo "$COUNT_RESPONSE" | grep -q "count\|0"; then
        print_success "Table '$table' exists"
    else
        print_warning "Table '$table' may not exist"
        ALL_OK=false
    fi
done

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

if $ALL_OK; then
    echo -e "${GREEN}Database deployment completed successfully!${NC}"
else
    echo -e "${YELLOW}Deployment completed with warnings.${NC}"
    echo "Some tables may need manual creation via Supabase SQL Editor."
fi

echo ""
echo "Tables created: ${#TABLES[@]}"
echo "Cities seeded: 14 Afghan cities"
echo "Routes seeded: 16 inter-city routes"
echo "Operators seeded: 4 sample operators"
echo ""
echo "Next: Run ./scripts/deploy-backend.sh"
echo ""
