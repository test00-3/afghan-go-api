require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3000;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const JWT_SECRET = process.env.JWT_SECRET || 'afghan-go-secret-2024';

app.use(cors());
app.use(express.json());

async function supabaseQuery(table, params = '', method = 'GET', body) {
  const url = `${SUPABASE_URL}/rest/v1/${table}${params ? '?' + params : ''}`;
  const headers = {
    'apikey': SUPABASE_KEY,
    'Authorization': `Bearer ${SUPABASE_KEY}`,
    'Content-Type': 'application/json',
  };
  if (method === 'POST' || method === 'PATCH') headers['Prefer'] = 'return=representation';
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(url, opts);
  if (!res.ok) {
    const err = await res.text();
    console.error(`Supabase error: ${res.status} - ${err}`);
    return [];
  }
  return res.json();
}

function auth(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'No token' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
}

app.get('/health', (req, res) => {
  res.json({ status: 'ok', server: 'Afghan Go API', timestamp: new Date().toISOString() });
});

app.post('/api/auth/otp/send', (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'Phone required' });
  console.log(`[OTP] Sent to ${phone}: 123456`);
  res.json({ success: true, message: 'OTP sent' });
});

app.post('/api/auth/otp/verify', async (req, res) => {
  const { phone, otp } = req.body;
  if (!phone || !otp) return res.status(400).json({ error: 'Phone and OTP required' });
  const users = await supabaseQuery('users', `phone_number=eq.${phone}&select=*`);
  let user = users?.[0];
  if (!user) {
    const newUser = await supabaseQuery('users', '', 'POST', {
      full_name: `User ${phone.slice(-4)}`,
      phone_number: phone,
      tazkira_number: `T${Date.now()}`,
      preferred_language: 'fa'
    });
    user = newUser?.[0];
  }
  const token = jwt.sign({ user_id: user.id, phone: user.phone_number }, JWT_SECRET, { expiresIn: '30d' });
  res.json({ success: true, token, user });
});

app.get('/api/auth/me', auth, async (req, res) => {
  const users = await supabaseQuery('users', `id=eq.${req.user.user_id}&select=*`);
  res.json({ success: true, user: users?.[0] });
});

app.get('/api/cities', (req, res) => {
  res.json({
    success: true,
    cities: ['Kabul', 'Herat', 'Mazar', 'Kandahar', 'Jalalabad', 'Kunduz', 'Bamyan', 'Lashkar Gah', 'Gardez', 'Taloqan', 'Sheberghan', 'Pul-e-Khumri', 'Mehtarlam', 'Panjshir']
  });
});

app.get('/api/trips', async (req, res) => {
  try {
    let params = 'status=eq.scheduled&available_seats=gt.0&select=*&order=departure_at.asc';
    if (req.query.origin) params += `&origin=eq.${req.query.origin}`;
    if (req.query.destination) params += `&destination=eq.${req.query.destination}`;
    const trips = await supabaseQuery('trips', params);
    res.json({ success: true, trips: trips || [] });
  } catch (err) {
    console.error('Trip search error:', err);
    res.status(500).json({ error: 'Failed to search trips' });
  }
});

app.get('/api/trips/:id', async (req, res) => {
  const trips = await supabaseQuery('trips', `id=eq.${req.params.id}&select=*,buses(*),transport_companies(*)`);
  if (!trips?.length) return res.status(404).json({ error: 'Trip not found' });
  res.json({ success: true, trip: trips[0] });
});

app.post('/api/bookings', auth, async (req, res) => {
  const { trip_id, seat_numbers, seat_class, payment_gateway } = req.body;
  const user_id = req.user.user_id;
  if (!trip_id || !seat_numbers?.length) {
    return res.status(400).json({ error: 'Trip ID and seats required' });
  }
  const trips = await supabaseQuery('trips', `id=eq.${trip_id}&select=*`);
  const trip = trips?.[0];
  if (!trip) return res.status(404).json({ error: 'Trip not found' });
  if (trip.available_seats < seat_numbers.length) {
    return res.status(400).json({ error: 'Not enough seats' });
  }
  const price = seat_class === 'vip' ? trip.vip_price : trip.normal_price;
  const total = price * seat_numbers.length;
  const deposit = Math.round(total * 0.2);
  const booking = await supabaseQuery('bookings', '', 'POST', {
    user_id, trip_id, bus_id: trip.bus_id,
    seat_numbers, seat_class: seat_class || 'normal',
    total_amount: total, deposit_amount: deposit,
    remaining_balance: total - deposit,
    payment_status: 'pending',
    payment_gateway: payment_gateway || 'hesabpay',
    trip_status: 'reserved',
  });
  await supabaseQuery('trips', `id=eq.${trip_id}`, 'PATCH', {
    available_seats: trip.available_seats - seat_numbers.length
  });
  res.json({ success: true, booking: booking?.[0] });
});

app.get('/api/bookings', auth, async (req, res) => {
  const bookings = await supabaseQuery('bookings',
    `user_id=eq.${req.user.user_id}&select=*,trips!bookings_trip_id_fkey(origin,destination,departure_at),transport_companies!trips_company_id_fkey(company_name)&order=booked_at.desc`
  );
  res.json({ success: true, bookings: bookings || [] });
});

app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

app.listen(PORT, () => {
  console.log(`Afghan Go API running on port ${PORT}`);
});
