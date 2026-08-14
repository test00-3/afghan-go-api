-- ============================================================================
-- Afghan Bus Ticket Booking System - Complete Database Schema
-- ============================================================================
-- Description: Unified PostgreSQL schema for an Afghan bus ticket booking
--              platform. Supports users, transport companies, buses, trips,
--              seat locking, bookings, payments, reviews, and notifications.
-- ============================================================================

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

DO $$ BEGIN
    CREATE TYPE bus_type AS ENUM ('standard', 'vip');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE trip_status AS ENUM ('scheduled', 'departed', 'completed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE seat_class AS ENUM ('normal', 'vip');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('pending', 'successful', 'failed', 'refunded');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_gateway AS ENUM ('hesabpay', 'momo', 'paypal');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE booking_trip_status AS ENUM ('reserved', 'in_transit', 'completed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE notification_type AS ENUM ('booking_confirmed', 'booking_cancelled', 'payment_received', 'trip_update', 'promotion', 'system');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE language_preference AS ENUM ('ps', 'fa', 'en');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TABLE: users
-- Description: Registered passengers who book bus tickets.
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name       VARCHAR(150) NOT NULL,
    phone_number    VARCHAR(20) NOT NULL UNIQUE,
    tazkira_number  VARCHAR(50) NOT NULL UNIQUE,
    preferred_language language_preference NOT NULL DEFAULT 'ps',
    fcm_token       TEXT,
    avatar_url      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_users_full_name CHECK (char_length(trim(full_name)) >= 2),
    CONSTRAINT chk_users_phone CHECK (phone_number ~ '^\+?[0-9]{9,15}$'),
    CONSTRAINT chk_users_tazkira CHECK (char_length(trim(tazkira_number)) >= 4)
);

COMMENT ON TABLE users IS 'Passengers who register and book bus tickets through the platform.';
COMMENT ON COLUMN users.id IS 'Unique identifier for the user.';
COMMENT ON COLUMN users.full_name IS 'Full name of the passenger.';
COMMENT ON COLUMN users.phone_number IS 'Phone number used for login and notifications. Must be unique.';
COMMENT ON COLUMN users.tazkira_number IS 'Afghan national ID (Tazkira) number. Must be unique.';
COMMENT ON COLUMN users.preferred_language IS 'Preferred UI language: Pashto (ps), Dari (fa), or English (en).';
COMMENT ON COLUMN users.fcm_token IS 'Firebase Cloud Messaging token for push notifications.';
COMMENT ON COLUMN users.avatar_url IS 'URL to the user''s profile picture.';

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE: transport_companies
-- Description: Licensed bus transport companies operating in Afghanistan.
-- ============================================================================

CREATE TABLE IF NOT EXISTS transport_companies (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name    VARCHAR(200) NOT NULL,
    logo_url        TEXT,
    central_phone   VARCHAR(20),
    rating          NUMERIC(3, 2) NOT NULL DEFAULT 0.00,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_company_name CHECK (char_length(trim(company_name)) >= 2),
    CONSTRAINT chk_company_rating CHECK (rating >= 0.00 AND rating <= 5.00),
    CONSTRAINT chk_company_central_phone CHECK (central_phone IS NULL OR central_phone ~ '^\+?[0-9]{9,15}$')
);

COMMENT ON TABLE transport_companies IS 'Bus transport companies registered on the platform.';
COMMENT ON COLUMN transport_companies.company_name IS 'Official name of the transport company.';
COMMENT ON COLUMN transport_companies.logo_url IS 'URL to the company logo image.';
COMMENT ON COLUMN transport_companies.central_phone IS 'Main customer service phone number.';
COMMENT ON COLUMN transport_companies.rating IS 'Average rating from 0.00 to 5.00 based on user reviews.';
COMMENT ON COLUMN transport_companies.is_active IS 'Whether the company is currently active on the platform.';

CREATE TRIGGER trg_transport_companies_updated_at
    BEFORE UPDATE ON transport_companies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE: buses
-- Description: Individual buses owned by transport companies.
-- ============================================================================

CREATE TABLE IF NOT EXISTS buses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID NOT NULL REFERENCES transport_companies(id) ON DELETE CASCADE,
    plate_number    VARCHAR(30) NOT NULL UNIQUE,
    bus_type        bus_type NOT NULL DEFAULT 'standard',
    total_seats     INTEGER NOT NULL,
    has_ac          BOOLEAN NOT NULL DEFAULT FALSE,
    has_meal        BOOLEAN NOT NULL DEFAULT FALSE,
    has_sleeper     BOOLEAN NOT NULL DEFAULT FALSE,
    bus_photo_url   TEXT,
    driver_name     VARCHAR(150),
    driver_photo_url TEXT,
    driver_phone    VARCHAR(20),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_bus_plate CHECK (char_length(trim(plate_number)) >= 3),
    CONSTRAINT chk_bus_total_seats CHECK (total_seats > 0 AND total_seats <= 80),
    CONSTRAINT chk_bus_driver_phone CHECK (driver_phone IS NULL OR driver_phone ~ '^\+?[0-9]{9,15}$')
);

COMMENT ON TABLE buses IS 'Individual buses operated by transport companies.';
COMMENT ON COLUMN buses.id IS 'Unique identifier for the bus.';
COMMENT ON COLUMN buses.company_id IS 'Foreign key to the owning transport company.';
COMMENT ON COLUMN buses.plate_number IS 'Unique vehicle plate number (Afghan format).';
COMMENT ON COLUMN buses.bus_type IS 'Type of bus: standard or vip.';
COMMENT ON COLUMN buses.total_seats IS 'Total number of passenger seats on the bus.';
COMMENT ON COLUMN buses.has_ac IS 'Whether the bus has air conditioning.';
COMMENT ON COLUMN buses.has_meal IS 'Whether meal service is available on the bus.';
COMMENT ON COLUMN buses.has_sleeper IS 'Whether the bus has sleeper seats.';
COMMENT ON COLUMN buses.driver_name IS 'Name of the assigned driver.';
COMMENT ON COLUMN buses.driver_phone IS 'Phone number of the assigned driver.';
COMMENT ON COLUMN buses.is_active IS 'Whether the bus is currently in service.';

CREATE TRIGGER trg_buses_updated_at
    BEFORE UPDATE ON buses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE: trips
-- Description: Scheduled bus trips between origin and destination cities.
-- ============================================================================

CREATE TABLE IF NOT EXISTS trips (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_id          UUID NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    company_id      UUID NOT NULL REFERENCES transport_companies(id) ON DELETE CASCADE,
    origin          VARCHAR(100) NOT NULL,
    destination     VARCHAR(100) NOT NULL,
    departure_at    TIMESTAMPTZ NOT NULL,
    arrival_at      TIMESTAMPTZ,
    normal_price    NUMERIC(10, 2) NOT NULL,
    vip_price       NUMERIC(10, 2) NOT NULL,
    available_seats INTEGER NOT NULL,
    status          trip_status NOT NULL DEFAULT 'scheduled',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_trip_origin CHECK (char_length(trim(origin)) >= 2),
    CONSTRAINT chk_trip_destination CHECK (char_length(trim(destination)) >= 2),
    CONSTRAINT chk_trip_prices CHECK (normal_price > 0 AND vip_price > 0),
    CONSTRAINT chk_trip_vip_ge_normal CHECK (vip_price >= normal_price),
    CONSTRAINT chk_trip_available_seats CHECK (available_seats >= 0),
    CONSTRAINT chk_trip_departure_future CHECK (departure_at > created_at),
    CONSTRAINT chk_trip_arrival CHECK (arrival_at IS NULL OR arrival_at > departure_at),
    CONSTRAINT chk_trip_origin_dest CHECK (origin <> destination)
);

COMMENT ON TABLE trips IS 'Scheduled bus trips with route, pricing, and availability.';
COMMENT ON COLUMN trips.id IS 'Unique identifier for the trip.';
COMMENT ON COLUMN trips.bus_id IS 'Foreign key to the bus assigned to this trip.';
COMMENT ON COLUMN trips.company_id IS 'Foreign key to the transport company operating this trip.';
COMMENT ON COLUMN trips.origin IS 'Departure city name (e.g., Kabul, Kandahar).';
COMMENT ON COLUMN trips.destination IS 'Arrival city name.';
COMMENT ON COLUMN trips.departure_at IS 'Scheduled departure date and time.';
COMMENT ON COLUMN trips.arrival_at IS 'Estimated arrival date and time.';
COMMENT ON COLUMN trips.normal_price IS 'Ticket price for standard/normal class in Afghan Afghani.';
COMMENT ON COLUMN trips.vip_price IS 'Ticket price for VIP class in Afghan Afghani.';
COMMENT ON COLUMN trips.available_seats IS 'Number of seats currently available for booking.';
COMMENT ON COLUMN trips.status IS 'Current status: scheduled, departed, completed, or cancelled.';

CREATE TRIGGER trg_trips_updated_at
    BEFORE UPDATE ON trips
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TABLE: seat_locks
-- Description: Temporary locks on seats during the booking process.
-- ============================================================================

CREATE TABLE IF NOT EXISTS seat_locks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    seat_number     VARCHAR(10) NOT NULL,
    booking_id      UUID,
    locked_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL,

    CONSTRAINT uq_seat_lock_trip_seat UNIQUE (trip_id, seat_number),
    CONSTRAINT chk_seat_number CHECK (char_length(trim(seat_number)) >= 1),
    CONSTRAINT chk_seat_lock_expiry CHECK (expires_at > locked_at)
);

COMMENT ON TABLE seat_locks IS 'Temporary seat reservations during the booking flow to prevent double-booking.';
COMMENT ON COLUMN seat_locks.trip_id IS 'The trip for which the seat is locked.';
COMMENT ON COLUMN seat_locks.seat_number IS 'The seat number being locked (e.g., A1, B12).';
COMMENT ON COLUMN seat_locks.booking_id IS 'Reference to the booking once confirmed. NULL while lock is temporary.';
COMMENT ON COLUMN seat_locks.locked_at IS 'Timestamp when the seat was locked.';
COMMENT ON COLUMN seat_locks.expires_at IS 'Timestamp when the lock expires and the seat becomes available again.';

-- ============================================================================
-- TABLE: bookings
-- Description: Passenger reservations for specific trips and seats.
-- ============================================================================

CREATE TABLE IF NOT EXISTS bookings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id             UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    bus_id              UUID NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    seat_numbers        TEXT[] NOT NULL,
    seat_class          seat_class NOT NULL DEFAULT 'normal',
    total_amount        NUMERIC(10, 2) NOT NULL,
    deposit_amount      NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    remaining_balance   NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    payment_status      payment_status NOT NULL DEFAULT 'pending',
    payment_gateway     payment_gateway,
    payment_reference   VARCHAR(255),
    trip_status         booking_trip_status NOT NULL DEFAULT 'reserved',
    cancellation_reason TEXT,
    booked_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_booking_seats_not_empty CHECK (array_length(seat_numbers, 1) > 0),
    CONSTRAINT chk_booking_total_amount CHECK (total_amount > 0),
    CONSTRAINT chk_booking_deposit CHECK (deposit_amount >= 0 AND deposit_amount <= total_amount),
    CONSTRAINT chk_booking_remaining CHECK (remaining_balance >= 0 AND remaining_balance = total_amount - deposit_amount),
    CONSTRAINT chk_booking_payment_ref CHECK (
        (payment_status = 'pending' AND payment_reference IS NULL) OR
        (payment_status <> 'pending' AND payment_reference IS NOT NULL)
    ),
    CONSTRAINT chk_booking_cancellation CHECK (
        (trip_status = 'cancelled' AND cancellation_reason IS NOT NULL AND char_length(cancellation_reason) > 0) OR
        (trip_status <> 'cancelled')
    )
);

COMMENT ON TABLE bookings IS 'Passenger reservations linking users to trips with seat assignments and payment details.';
COMMENT ON COLUMN bookings.id IS 'Unique identifier for the booking.';
COMMENT ON COLUMN bookings.user_id IS 'Foreign key to the passenger who made the booking.';
COMMENT ON COLUMN bookings.trip_id IS 'Foreign key to the reserved trip.';
COMMENT ON COLUMN bookings.bus_id IS 'Foreign key to the bus for this booking.';
COMMENT ON COLUMN bookings.seat_numbers IS 'Array of seat numbers reserved (e.g., ARRAY[''A1'', ''A2'']).';
COMMENT ON COLUMN bookings.seat_class IS 'Class of seating: normal or vip.';
COMMENT ON COLUMN bookings.total_amount IS 'Total cost of all reserved seats.';
COMMENT ON COLUMN bookings.deposit_amount IS 'Amount already paid as deposit.';
COMMENT ON COLUMN bookings.remaining_balance IS 'Amount still owed (total_amount - deposit_amount).';
COMMENT ON COLUMN bookings.payment_status IS 'Current payment status: pending, successful, failed, or refunded.';
COMMENT ON COLUMN bookings.payment_gateway IS 'Payment gateway used for the transaction.';
COMMENT ON COLUMN bookings.payment_reference IS 'Transaction reference ID from the payment gateway.';
COMMENT ON COLUMN bookings.trip_status IS 'Booking trip status: reserved, in_transit, completed, or cancelled.';
COMMENT ON COLUMN bookings.cancellation_reason IS 'Reason for cancellation (required if trip_status is cancelled).';
COMMENT ON COLUMN bookings.booked_at IS 'Timestamp when the booking was created.';

CREATE TRIGGER trg_bookings_updated_at
    BEFORE UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add FK from seat_locks.booking_id to bookings.id (deferred to avoid circular dependency)
ALTER TABLE seat_locks
    ADD CONSTRAINT fk_seat_locks_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL;

-- ============================================================================
-- TABLE: payments
-- Description: Payment transaction ledger for all booking payments.
-- ============================================================================

CREATE TABLE IF NOT EXISTS payments (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id              UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    amount                  NUMERIC(10, 2) NOT NULL,
    gateway                 payment_gateway NOT NULL,
    gateway_transaction_id  VARCHAR(255),
    status                  payment_status NOT NULL DEFAULT 'pending',
    metadata                JSONB DEFAULT '{}'::jsonb,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    CONSTRAINT chk_payment_gateway_txn CHECK (
        (status = 'pending' AND gateway_transaction_id IS NULL) OR
        (status <> 'pending' AND gateway_transaction_id IS NOT NULL AND char_length(gateway_transaction_id) > 0)
    )
);

COMMENT ON TABLE payments IS 'Ledger of all payment transactions associated with bookings.';
COMMENT ON COLUMN payments.id IS 'Unique identifier for the payment record.';
COMMENT ON COLUMN payments.booking_id IS 'Foreign key to the associated booking.';
COMMENT ON COLUMN payments.amount IS 'Payment amount in Afghan Afghani.';
COMMENT ON COLUMN payments.gateway IS 'Payment gateway used: hesabpay, momo, or paypal.';
COMMENT ON COLUMN payments.gateway_transaction_id IS 'Transaction ID returned by the payment gateway.';
COMMENT ON COLUMN payments.status IS 'Payment status: pending, successful, failed, or refunded.';
COMMENT ON COLUMN payments.metadata IS 'Additional gateway response data stored as JSON.';

-- ============================================================================
-- TABLE: reviews
-- Description: User reviews and ratings for completed trips.
-- ============================================================================

CREATE TABLE IF NOT EXISTS reviews (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id     UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    rating      INTEGER NOT NULL,
    comment     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_review_rating CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT chk_review_comment CHECK (comment IS NULL OR char_length(trim(comment)) >= 1),
    CONSTRAINT uq_review_user_trip UNIQUE (user_id, trip_id)
);

COMMENT ON TABLE reviews IS 'User-submitted reviews and ratings for completed trips.';
COMMENT ON COLUMN reviews.id IS 'Unique identifier for the review.';
COMMENT ON COLUMN reviews.user_id IS 'Foreign key to the user who wrote the review.';
COMMENT ON COLUMN reviews.trip_id IS 'Foreign key to the trip being reviewed.';
COMMENT ON COLUMN reviews.rating IS 'Rating from 1 to 5.';
COMMENT ON COLUMN reviews.comment IS 'Optional text review.';
COMMENT ON COLUMN reviews.created_at IS 'Timestamp when the review was submitted.';

-- ============================================================================
-- TABLE: notifications
-- Description: In-app notifications for users.
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    body        TEXT NOT NULL,
    type        notification_type NOT NULL DEFAULT 'system',
    data        JSONB DEFAULT '{}'::jsonb,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_notification_title CHECK (char_length(trim(title)) >= 1),
    CONSTRAINT chk_notification_body CHECK (char_length(trim(body)) >= 1)
);

COMMENT ON TABLE notifications IS 'In-app notifications sent to users about bookings, payments, and system updates.';
COMMENT ON COLUMN notifications.id IS 'Unique identifier for the notification.';
COMMENT ON COLUMN notifications.user_id IS 'Foreign key to the recipient user.';
COMMENT ON COLUMN notifications.title IS 'Notification title/headline.';
COMMENT ON COLUMN notifications.body IS 'Notification body text.';
COMMENT ON COLUMN notifications.type IS 'Type of notification: booking_confirmed, booking_cancelled, payment_received, trip_update, promotion, or system.';
COMMENT ON COLUMN notifications.data IS 'Additional structured data as JSON (e.g., booking_id, trip details).';
COMMENT ON COLUMN notifications.is_read IS 'Whether the user has read this notification.';
COMMENT ON COLUMN notifications.created_at IS 'Timestamp when the notification was created.';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Trips indexes
CREATE INDEX IF NOT EXISTS idx_trips_origin_destination ON trips (origin, destination);
CREATE INDEX IF NOT EXISTS idx_trips_departure_at ON trips (departure_at);
CREATE INDEX IF NOT EXISTS idx_trips_company_id ON trips (company_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON trips (status);
CREATE INDEX IF NOT EXISTS idx_trips_bus_id ON trips (bus_id);
CREATE INDEX IF NOT EXISTS idx_trips_status_departure ON trips (status, departure_at);

-- Bookings indexes
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings (user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_trip_id ON bookings (trip_id);
CREATE INDEX IF NOT EXISTS idx_bookings_payment_trip_status ON bookings (payment_status, trip_status);
CREATE INDEX IF NOT EXISTS idx_bookings_bus_id ON bookings (bus_id);
CREATE INDEX IF NOT EXISTS idx_bookings_booked_at ON bookings (booked_at);

-- Seat locks indexes
CREATE INDEX IF NOT EXISTS idx_seat_locks_trip_seat ON seat_locks (trip_id, seat_number);
CREATE INDEX IF NOT EXISTS idx_seat_locks_booking_id ON seat_locks (booking_id);
CREATE INDEX IF NOT EXISTS idx_seat_locks_expires_at ON seat_locks (expires_at);
CREATE INDEX IF NOT EXISTS idx_seat_locks_trip_id ON seat_locks (trip_id);

-- Payments indexes
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON payments (booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_gateway_transaction_id ON payments (gateway_transaction_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments (status);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments (created_at);

-- Reviews indexes
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews (user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_trip_id ON reviews (trip_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews (rating);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_is_read ON notifications (user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications (type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications (created_at);

-- Buses indexes
CREATE INDEX IF NOT EXISTS idx_buses_company_id ON buses (company_id);
CREATE INDEX IF NOT EXISTS idx_buses_plate_number ON buses (plate_number);
CREATE INDEX IF NOT EXISTS idx_buses_is_active ON buses (is_active);

-- Transport companies indexes
CREATE INDEX IF NOT EXISTS idx_transport_companies_is_active ON transport_companies (is_active);

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_phone_number ON users (phone_number);
CREATE INDEX IF NOT EXISTS idx_users_tazkira_number ON users (tazkira_number);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES FOR SUPABASE
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE seat_locks ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users: Users can only read/update their own profile
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Transport companies: Public read, admin write (handled via service role)
CREATE POLICY "Anyone can view active transport companies"
    ON transport_companies FOR SELECT
    USING (is_active = TRUE);

-- Buses: Public read for active buses
CREATE POLICY "Anyone can view active buses"
    ON buses FOR SELECT
    USING (is_active = TRUE);

-- Trips: Public read for scheduled trips
CREATE POLICY "Anyone can view scheduled trips"
    ON trips FOR SELECT
    USING (status = 'scheduled');

-- Seat locks: Users can view locks on trips they have bookings for
CREATE POLICY "Users can view seat locks for booking flow"
    ON seat_locks FOR SELECT
    USING (TRUE);

CREATE POLICY "Users can insert seat locks"
    ON seat_locks FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update own seat locks"
    ON seat_locks FOR UPDATE
    USING (booking_id IN (
        SELECT id FROM bookings WHERE user_id = auth.uid()
    ));

CREATE POLICY "Users can delete expired seat locks"
    ON seat_locks FOR DELETE
    USING (expires_at < NOW() OR booking_id IN (
        SELECT id FROM bookings WHERE user_id = auth.uid()
    ));

-- Bookings: Users can only see/manage their own bookings
CREATE POLICY "Users can view own bookings"
    ON bookings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own bookings"
    ON bookings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own bookings"
    ON bookings FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Payments: Users can view payments for their own bookings
CREATE POLICY "Users can view own payments"
    ON payments FOR SELECT
    USING (booking_id IN (
        SELECT id FROM bookings WHERE user_id = auth.uid()
    ));

CREATE POLICY "Users can insert payments for own bookings"
    ON payments FOR INSERT
    WITH CHECK (booking_id IN (
        SELECT id FROM bookings WHERE user_id = auth.uid()
    ));

-- Reviews: Public read, users can manage their own reviews
CREATE POLICY "Anyone can view reviews"
    ON reviews FOR SELECT
    USING (TRUE);

CREATE POLICY "Users can insert own reviews"
    ON reviews FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reviews"
    ON reviews FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own reviews"
    ON reviews FOR DELETE
    USING (auth.uid() = user_id);

-- Notifications: Users can only see their own notifications
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications (mark as read)"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role can insert notifications"
    ON notifications FOR INSERT
    WITH CHECK (TRUE);

-- ============================================================================
-- CLEANUP FUNCTION: Auto-expire stale seat locks
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_expired_seat_locks()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM seat_locks
    WHERE expires_at < NOW()
      AND booking_id IS NULL;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_expired_seat_locks() IS 'Removes seat locks that have expired and are not linked to a booking. Returns count of deleted locks.';

-- ============================================================================
-- FUNCTION: Recalculate available seats for a trip based on confirmed bookings
-- ============================================================================

CREATE OR REPLACE FUNCTION recalculate_available_seats(p_trip_id UUID)
RETURNS VOID AS $$
DECLARE
    v_total_seats INTEGER;
    v_booked_seats INTEGER;
BEGIN
    SELECT b.total_seats INTO v_total_seats
    FROM trips t
    JOIN buses b ON t.bus_id = b.id
    WHERE t.id = p_trip_id;

    SELECT COALESCE(SUM(array_length(seat_numbers, 1)), 0) INTO v_booked_seats
    FROM bookings
    WHERE trip_id = p_trip_id
      AND payment_status = 'successful'
      AND trip_status <> 'cancelled';

    UPDATE trips
    SET available_seats = GREATEST(v_total_seats - v_booked_seats, 0)
    WHERE id = p_trip_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION recalculate_available_seats(UUID) IS 'Recalculates and updates available_seats for a trip based on successful, non-cancelled bookings.';

-- ============================================================================
-- SCHEMA COMPLETE
-- ============================================================================
