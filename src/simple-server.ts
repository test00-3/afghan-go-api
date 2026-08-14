import express from 'express';
import cors from 'cors';
import { createClient } from '@supabase/supabase-js';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Supabase (disable realtime to avoid WebSocket issues on Node 20)
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  {
    auth: { persistSession: false, autoRefreshToken: false },
    realtime: { params: { eventsPerSecond: 0 } },
  }
);

// Middleware
app.use(cors());
app.use(express.json());

// Auth middleware
function auth(req: any, res: any, next: any) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'No token' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'demo-secret');
    req.user = decoded;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// ============ HEALTH ============
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ============ AUTH ============
app.post('/api/auth/otp/send', async (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'Phone required' });
  
  // Demo: always succeed
  const otp = '123456';
  console.log(`[OTP] Sent to ${phone}: ${otp}`);
  
  res.json({ success: true, message: 'OTP sent', phone });
});

app.post('/api/auth/otp/verify', async (req, res) => {
  const { phone, otp } = req.body;
  if (!phone || !otp) return res.status(400).json({ error: 'Phone and OTP required' });
  
  // Demo: accept any 6-digit OTP
  if (otp.length !== 6) {
    return res.status(400).json({ error: 'Invalid OTP' });
  }

  // Find or create user
  let { data: user } = await supabase
    .from('users')
    .select('*')
    .eq('phone_number', phone)
    .single();

  if (!user) {
    const { data: newUser } = await supabase
      .from('users')
      .insert({
        full_name: `User ${phone.slice(-4)}`,
        phone_number: phone,
        tazkira_number: `T${Date.now()}`,
        preferred_language: 'fa'
      })
      .select()
      .single();
    user = newUser;
  }

  // Generate JWT
  const token = jwt.sign(
    { user_id: user!.id, phone: user!.phone_number },
    process.env.JWT_SECRET || 'demo-secret',
    { expiresIn: '30d' }
  );

  res.json({ success: true, token, user: user });
});

app.get('/api/auth/me', auth, async (req: any, res) => {
  const { data: user } = await supabase
    .from('users')
    .select('*')
    .eq('id', req.user.user_id)
    .single();
  
  res.json({ success: true, user });
});

// ============ CITIES ============
app.get('/api/cities', async (req, res) => {
  const cities = [
    'Kabul', 'Herat', 'Mazar', 'Kandahar', 'Jalalabad',
    'Kunduz', 'Bamyan', 'Lashkar Gah', 'Gardez', 'Taloqan',
    'Sheberghan', 'Pul-e-Khumri', 'Mehtarlam', 'Panjshir'
  ];
  res.json({ success: true, cities });
});

// ============ TRIPS ============
app.get('/api/trips', async (req, res) => {
  const { origin, destination, date } = req.query;
  
  let query = supabase
    .from('trips')
    .select(`
      *,
      buses!trips_bus_id_fkey(plate_number, bus_type, driver_name, driver_phone, has_ac, has_meal, has_sleeper),
      transport_companies!trips_company_id_fkey(company_name, rating, central_phone)
    `)
    .eq('status', 'scheduled')
    .gt('available_seats', 0);

  if (origin) query = query.eq('origin', origin);
  if (destination) query = query.eq('destination', destination);

  const { data: trips, error } = await query;

  if (error) {
    console.error('Trip search error:', error);
    return res.status(500).json({ error: 'Failed to search trips' });
  }

  // Format response
  const formattedTrips = (trips || []).map((trip: any) => ({
    id: trip.id,
    origin: trip.origin,
    destination: trip.destination,
    departure_at: trip.departure_at,
    arrival_at: trip.arrival_at,
    normal_price: trip.normal_price,
    vip_price: trip.vip_price,
    available_seats: trip.available_seats,
    bus: {
      plate_number: trip.buses?.plate_number,
      bus_type: trip.buses?.bus_type,
      driver_name: trip.buses?.driver_name,
      driver_phone: trip.buses?.driver_phone,
      has_ac: trip.buses?.has_ac,
      has_meal: trip.buses?.has_meal,
      has_sleeper: trip.buses?.has_sleeper,
    },
    company: {
      name: trip.transport_companies?.company_name,
      rating: trip.transport_companies?.rating,
      phone: trip.transport_companies?.central_phone,
    }
  }));

  res.json({ success: true, trips: formattedTrips });
});

app.get('/api/trips/:id', async (req, res) => {
  const { data: trip, error } = await supabase
    .from('trips')
    .select(`
      *,
      buses!trips_bus_id_fkey(*),
      transport_companies!trips_company_id_fkey(*)
    `)
    .eq('id', req.params.id)
    .single();

  if (error || !trip) {
    return res.status(404).json({ error: 'Trip not found' });
  }

  res.json({ success: true, trip });
});

// ============ BOOKINGS ============
app.post('/api/bookings', auth, async (req: any, res) => {
  const { trip_id, seat_numbers, seat_class, payment_gateway } = req.body;
  const user_id = req.user.user_id;

  if (!trip_id || !seat_numbers?.length) {
    return res.status(400).json({ error: 'Trip ID and seats required' });
  }

  // Get trip details
  const { data: trip } = await supabase
    .from('trips')
    .select('*')
    .eq('id', trip_id)
    .single();

  if (!trip) return res.status(404).json({ error: 'Trip not found' });
  if (trip.available_seats < seat_numbers.length) {
    return res.status(400).json({ error: 'Not enough seats' });
  }

  // Calculate price
  const price = seat_class === 'vip' ? trip.vip_price : trip.normal_price;
  const total = price * seat_numbers.length;
  const deposit = Math.round(total * 0.2);
  const remaining = total - deposit;

  // Create booking
  const { data: booking, error } = await supabase
    .from('bookings')
    .insert({
      user_id,
      trip_id,
      bus_id: trip.bus_id,
      seat_numbers,
      seat_class: seat_class || 'normal',
      total_amount: total,
      deposit_amount: deposit,
      remaining_balance: remaining,
      payment_status: 'pending',
      payment_gateway: payment_gateway || 'hesabpay',
      trip_status: 'reserved',
    })
    .select()
    .single();

  if (error) {
    console.error('Booking error:', error);
    return res.status(500).json({ error: 'Failed to create booking' });
  }

  // Update available seats
  await supabase
    .from('trips')
    .update({ available_seats: trip.available_seats - seat_numbers.length })
    .eq('id', trip_id);

  res.json({
    success: true,
    booking: {
      id: booking.id,
      seats: seat_numbers,
      total,
      deposit,
      remaining,
      payment_gateway,
      status: 'pending',
    }
  });
});

app.get('/api/bookings', auth, async (req: any, res) => {
  const { data: bookings } = await supabase
    .from('bookings')
    .select(`
      *,
      trips!bookings_trip_id_fkey(origin, destination, departure_at),
      transport_companies!trips_company_id_fkey(company_name)
    `)
    .eq('user_id', req.user.user_id)
    .order('booked_at', { ascending: false });

  res.json({ success: true, bookings: bookings || [] });
});

// ============ REVIEWS ============
app.get('/api/trips/:id/reviews', async (req, res) => {
  const { data: reviews } = await supabase
    .from('reviews')
    .select('*, users(full_name)')
    .eq('trip_id', req.params.id)
    .order('created_at', { ascending: false });

  res.json({ success: true, reviews: reviews || [] });
});

// ============ START ============
app.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════════════════════════╗
║           Afghan Go API Server Started                   ║
║           Port: ${PORT}                                    ║
║           URL: http://localhost:${PORT}                    ║
╚══════════════════════════════════════════════════════════╝
  `);
});
