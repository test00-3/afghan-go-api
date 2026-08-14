# FlutterFlow Setup Guide - Afghan Go

## Backend Configuration

### Step 1: Set Base URL
1. Go to **Settings** → **Backend Connectors**
2. Set **Base URL** based on your setup:

| Environment | Base URL |
|-------------|----------|
| Android Emulator | `http://10.0.2.2:3000` |
| iOS Simulator | `http://localhost:3000` |
| Real Device (same WiFi) | `http://[YOUR-PC-IP]:3000` |
| Production (Render) | `https://afghan-go-api.onrender.com` |

### Step 2: Set Headers
```
Content-Type: application/json
Authorization: Bearer <token>
```

---

## API Calls to Create in FlutterFlow

### 1. Send OTP (Login)
```
Name: SendOTP
Method: POST
URL: /api/auth/otp/send
Body:
{
  "phone": "+93700123456"
}
Response:
{
  "success": true,
  "otp": "123456"  // Remove this in production
}
```

### 2. Verify OTP
```
Name: VerifyOTP
Method: POST
URL: /api/auth/otp/verify
Body:
{
  "phone": "+93700123456",
  "otp": "123456"
}
Response:
{
  "success": true,
  "token": "jwt-token-here",
  "user": {
    "id": "uuid",
    "phone": "+93700123456",
    "full_name": "User Name"
  }
}
```

### 3. Get Trips (Search)
```
Name: GetTrips
Method: GET
URL: /api/trips
Query Params:
  origin: Kabul
  destination: Kandahar
  date: 2026-08-15
Response:
{
  "success": true,
  "trips": [...]
}
```

### 4. Get Trip Details
```
Name: GetTripDetail
Method: GET
URL: /api/trips/{trip_id}
Response:
{
  "success": true,
  "trip": {...}
}
```

### 5. Create Booking
```
Name: CreateBooking
Method: POST
URL: /api/bookings
Headers:
  Authorization: Bearer {token}
Body:
{
  "trip_id": "uuid",
  "seat_numbers": [1, 2],
  "seat_type": "normal"
}
Response:
{
  "success": true,
  "booking": {
    "id": "uuid",
    "booking_ref": "BG-XXXXXX",
    "total_amount": 1400,
    "status": "confirmed"
  }
}
```

### 6. Get My Bookings
```
Name: GetMyBookings
Method: GET
URL: /api/bookings
Headers:
  Authorization: Bearer {token}
Response:
{
  "success": true,
  "bookings": [...]
}
```

### 7. Get Cities
```
Name: GetCities
Method: GET
URL: /api/cities
Response:
{
  "success": true,
  "cities": ["Kabul", "Herat", "Mazar", "Kandahar", "Jalalabad", "Kunduz"]
}
```

### 8. Cancel Booking
```
Name: CancelBooking
Method: POST
URL: /api/bookings/{booking_id}/cancel
Headers:
  Authorization: Bearer {token}
Response:
{
  "success": true,
  "message": "Booking cancelled"
}
```

---

## Page Structure in FlutterFlow

### Required Pages:
1. **SplashPage** - App logo, auto-navigate
2. **LoginPage** - Phone input + Send OTP button
3. **OTPPage** - Enter OTP code
4. **HomePage** - Search form (origin, destination, date)
5. **TripListPage** - List of available trips
6. **TripDetailPage** - Trip info + seat selection
7. **SeatSelectionPage** - Visual seat map
8. **BookingConfirmPage** - Summary before booking
9. **BookingSuccessPage** - Confirmation with ref number
10. **MyBookingsPage** - User's booking history
11. **ProfilePage** - User profile + logout

---

## State Management

Use **App State** (Global Properties) to store:
- `currentUser` - Logged in user data
- `authToken` - JWT token
- `selectedOrigin` - Selected departure city
- `selectedDestination` - Selected arrival city
- `selectedDate` - Travel date
- `selectedTrip` - Current trip being viewed
- `selectedSeats` - Array of selected seat numbers

---

## Test Data

Available cities:
```
Kabul, Herat, Mazar, Kandahar, Jalalabad, Kunduz
```

Sample trip for testing:
```
Origin: Kabul
Destination: Kandahar
Date: 2026-08-15
Price: 700 AFN (Normal) / 1100 AFN (VIP)
```

---

## Common Issues

### 1. CORS Error
Add to server if needed:
```typescript
app.use(cors({
  origin: ['https://*.flutterflow.io', 'http://localhost:8080'],
  credentials: true
}));
```

### 2. Connection Refused (Real Device)
- Make sure PC and phone are on same WiFi
- Check Windows Firewall allows port 3000
- Use `http://[PC-IP]:3000` not `http://localhost:3000`

### 3. SSL Error (Android)
Add network security config for HTTP:
- Android Manifest: `android:usesCleartextTraffic="true"`
