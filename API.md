# Afghan Go - API Documentation

Complete REST API documentation for the Afghan Go Bus Ticket Booking System.

Base URL: `https://api.afghango.app/api/v1`

---

## Authentication

All authenticated endpoints require a Bearer token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

Tokens expire after 7 days. Use the refresh endpoint to obtain new tokens.

---

## Endpoints

### Authentication

#### POST /auth/register

Register a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "phone": "+93700123456",
  "password": "SecurePass123!",
  "full_name": "Ahmad Khan",
  "national_id": "1234567890",
  "preferred_language": "en"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid-here",
      "email": "user@example.com",
      "phone": "+93700123456",
      "full_name": "Ahmad Khan"
    },
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**Errors:**
- `400` - Validation error
- `409` - Email/phone already registered

---

#### POST /auth/login

Authenticate user and receive JWT token.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid-here",
      "email": "user@example.com",
      "full_name": "Ahmad Khan",
      "preferred_language": "en"
    },
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**Errors:**
- `401` - Invalid credentials
- `404` - User not found

---

#### POST /auth/refresh

Refresh an expired JWT token.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

### Cities

#### GET /cities

List all available cities.

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-here",
      "name_en": "Kabul",
      "name_fa": "کابل",
      "name_ps": "کابل",
      "province": "Kabul",
      "latitude": 34.5553,
      "longitude": 69.2075
    }
  ],
  "count": 14
}
```

---

### Trips

#### GET /trips/search

Search for available trips between two cities.

**Query Parameters:**
| Parameter      | Type     | Required | Description                        |
|----------------|----------|----------|------------------------------------|
| origin         | string   | Yes      | Origin city name or ID             |
| destination    | string   | Yes      | Destination city name or ID        |
| date           | string   | Yes      | Travel date (YYYY-MM-DD)           |
| passengers     | number   | No       | Number of passengers (default: 1)  |
| vip_only       | boolean  | No       | Filter VIP buses only              |

**Example:**
```
GET /trips/search?origin=Kabul&destination=Herat&date=2026-08-20&passengers=2
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "trip-uuid",
      "route": {
        "id": "route-uuid",
        "origin": { "name_en": "Kabul", "name_fa": "کابل" },
        "destination": { "name_en": "Herat", "name_fa": "هرات" },
        "distance_km": 645,
        "duration_minutes": 480
      },
      "bus": {
        "id": "bus-uuid",
        "operator": {
          "name": "Afghan Go Express",
          "is_vip": true,
          "rating": 4.5
        },
        "plate_number": "KBL-1234",
        "bus_type": "standard",
        "total_seats": 40,
        "amenities": ["wifi", "ac", "charging"]
      },
      "departure_time": "2026-08-20T06:00:00Z",
      "arrival_time": "2026-08-20T14:00:00Z",
      "base_price": 800.00,
      "vip_price": 1200.00,
      "available_seats": 35,
      "currency": "AFN"
    }
  ],
  "count": 5,
  "filters": {
    "date": "2026-08-20",
    "origin": "Kabul",
    "destination": "Herat"
  }
}
```

**Errors:**
- `400` - Missing required parameters
- `404` - No routes found

---

#### GET /trips/:id

Get detailed information about a specific trip.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "trip-uuid",
    "route": { "...": "..." },
    "bus": { "...": "..." },
    "departure_time": "2026-08-20T06:00:00Z",
    "arrival_time": "2026-08-20T14:00:00Z",
    "base_price": 800.00,
    "available_seats": 35,
    "seat_map": [
      {
        "seat_number": "A1",
        "row_number": 1,
        "column_letter": "A",
        "seat_type": "standard",
        "is_available": true,
        "extra_price": 0
      }
    ]
  }
}
```

---

#### GET /trips/:id/seats

Get real-time seat availability for a trip.

**Query Parameters:**
| Parameter | Type    | Required | Description                         |
|-----------|---------|----------|-------------------------------------|
| locked   | boolean | No       | Show only locked seats (admin)      |

**Response (200):**
```json
{
  "success": true,
  "data": {
    "trip_id": "trip-uuid",
    "total_seats": 40,
    "available_seats": 35,
    "locked_seats": 3,
    "booked_seats": 2,
    "seats": [
      {
        "seat_number": "A1",
        "is_available": true,
        "is_locked": false,
        "is_booked": false,
        "seat_type": "standard",
        "extra_price": 0
      },
      {
        "seat_number": "A2",
        "is_available": false,
        "is_locked": true,
        "is_booked": false,
        "locked_by": "other-user-id",
        "expires_at": "2026-08-14T12:05:00Z"
      },
      {
        "seat_number": "A3",
        "is_available": false,
        "is_locked": false,
        "is_booked": true,
        "seat_type": "standard"
      }
    ]
  }
}
```

---

### Bookings

#### POST /bookings

Create a new booking (reserves seats with 30-minute lock).

**Request:**
```json
{
  "trip_id": "trip-uuid",
  "seat_numbers": ["A1", "A2"],
  "passenger_name": "Ahmad Khan",
  "passenger_phone": "+93700123456",
  "passenger_national_id": "1234567890",
  "notes": "Window seat preferred"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "booking-uuid",
    "booking_reference": "AFG2608140123",
    "status": "pending",
    "trip": {
      "departure_time": "2026-08-20T06:00:00Z",
      "route": {
        "origin": { "name_en": "Kabul" },
        "destination": { "name_en": "Herat" }
      }
    },
    "seat_numbers": ["A1", "A2"],
    "total_amount": 1600.00,
    "deposit_amount": 320.00,
    "remaining_amount": 1280.00,
    "currency": "AFN",
    "passenger_name": "Ahmad Khan",
    "passenger_phone": "+93700123456",
    "expires_at": "2026-08-14T12:30:00Z",
    "created_at": "2026-08-14T12:00:00Z"
  }
}
```

**Errors:**
- `400` - Validation error
- `409` - Seat already taken
- `422` - Not enough available seats

---

#### GET /bookings/:id

Get booking details (own bookings only).

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "booking-uuid",
    "booking_reference": "AFG2608140123",
    "status": "paid_deposit",
    "trip": { "...": "..." },
    "seat_numbers": ["A1", "A2"],
    "total_amount": 1600.00,
    "deposit_amount": 320.00,
    "remaining_amount": 1280.00,
    "payments": [
      {
        "id": "payment-uuid",
        "payment_method": "hesabpay",
        "amount": 320.00,
        "status": "completed",
        "transaction_id": "HP-123456",
        "paid_at": "2026-08-14T12:05:00Z"
      }
    ],
    "qr_code_url": "https://api.afghango.app/tickets/AFG2608140123/qr",
    "passenger_name": "Ahmad Khan",
    "passenger_phone": "+93700123456"
  }
}
```

---

#### GET /bookings

List user's bookings.

**Query Parameters:**
| Parameter | Type   | Required | Description                         |
|-----------|--------|----------|-------------------------------------|
| status    | string | No       | Filter by status                    |
| page      | number | No       | Page number (default: 1)            |
| limit     | number | No       | Results per page (default: 20)      |

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "booking-uuid",
      "booking_reference": "AFG2608140123",
      "status": "paid_full",
      "trip_summary": {
        "origin": "Kabul",
        "destination": "Herat",
        "departure_time": "2026-08-20T06:00:00Z"
      },
      "seat_numbers": ["A1", "A2"],
      "total_amount": 1600.00,
      "created_at": "2026-08-14T12:00:00Z"
    }
  ],
  "pagination": {
    "total": 15,
    "page": 1,
    "limit": 20,
    "total_pages": 1
  }
}
```

---

#### POST /bookings/:id/cancel

Cancel a booking and release seats.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "booking-uuid",
    "status": "cancelled",
    "refund_amount": 320.00,
    "refund_method": "Original payment method",
    "cancelled_at": "2026-08-14T13:00:00Z"
  }
}
```

---

### Payments

#### POST /bookings/:id/pay

Process payment for a booking.

**Request:**
```json
{
  "payment_method": "hesabpay",
  "amount": 320.00,
  "currency": "AFN",
  "return_url": "https://afghango.app/payment/complete"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "payment_id": "payment-uuid",
    "payment_method": "hesabpay",
    "amount": 320.00,
    "status": "processing",
    "gateway_url": "https://hesabpay.com/pay/abc123",
    "transaction_id": "HP-123456",
    "expires_at": "2026-08-14T12:30:00Z"
  }
}
```

---

#### POST /payments/hesabpay/callback

HesabPay webhook callback (called by gateway).

**Request:**
```json
{
  "transaction_id": "HP-123456",
  "status": "successful",
  "amount": 320.00,
  "merchant_id": "your-merchant-id",
  "signature": "verified-signature"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Payment processed"
}
```

---

#### POST /payments/momo/callback

MoMo Money webhook callback.

**Request:**
```json
{
  "transaction_id": "MMO-789012",
  "status": "SUCCESS",
  "amount": 320.00,
  "phone": "+93700123456",
  "reference": "booking-reference"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Payment processed"
}
```

---

### Tickets

#### GET /bookings/:id/ticket

Get QR code ticket for a booking.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "booking_reference": "AFG2608140123",
    "qr_code_base64": "data:image/png;base64,...",
    "qr_code_url": "https://api.afghango.app/tickets/AFG2608140123/qr",
    "ticket_data": {
      "passenger": "Ahmad Khan",
      "phone": "+93700123456",
      "route": "Kabul → Herat",
      "bus_operator": "Afghan Go Express",
      "plate_number": "KBL-1234",
      "seats": ["A1", "A2"],
      "departure": "2026-08-20 06:00",
      "arrival": "2026-08-20 14:00",
      "amount_paid": "320 AFN",
      "status": "paid_deposit"
    },
    "valid_until": "2026-08-20T06:00:00Z"
  }
}
```

---

### User Profile

#### GET /profile

Get current user's profile.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid-here",
    "user_id": "auth-uuid",
    "full_name": "Ahmad Khan",
    "phone": "+93700123456",
    "national_id": "1234567890",
    "preferred_language": "en",
    "total_bookings": 5,
    "created_at": "2026-01-01T00:00:00Z"
  }
}
```

---

#### PUT /profile

Update user profile.

**Request:**
```json
{
  "full_name": "Ahmad Khan Updated",
  "phone": "+93700987654",
  "preferred_language": "fa"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid-here",
    "full_name": "Ahmad Khan Updated",
    "phone": "+93700987654",
    "preferred_language": "fa"
  }
}
```

---

### Notifications

#### GET /notifications

Get user notifications.

**Query Parameters:**
| Parameter | Type    | Required | Description                         |
|-----------|---------|----------|-------------------------------------|
| unread    | boolean | No       | Filter unread only                  |
| page      | number  | No       | Page number                         |
| limit     | number  | No       | Results per page                    |

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "notif-uuid",
      "title": "Booking Confirmed",
      "title_fa": "رزرو تایید شد",
      "message": "Your booking AFG2608140123 has been confirmed.",
      "message_fa": "رزرو شما AFG2608140123 تایید شد.",
      "type": "booking_confirmed",
      "is_read": false,
      "data": {
        "booking_id": "booking-uuid",
        "booking_reference": "AFG2608140123"
      },
      "created_at": "2026-08-14T12:05:00Z"
    }
  ],
  "unread_count": 3
}
```

---

#### PUT /notifications/:id/read

Mark notification as read.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "notif-uuid",
    "is_read": true,
    "read_at": "2026-08-14T13:00:00Z"
  }
}
```

---

#### PUT /notifications/read-all

Mark all notifications as read.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "updated_count": 3
  }
}
```

---

### Reviews

#### POST /reviews

Create a review for a completed trip.

**Request:**
```json
{
  "trip_id": "trip-uuid",
  "operator_id": "operator-uuid",
  "rating": 5,
  "comment": "Excellent service and comfortable bus",
  "is_anonymous": false
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "review-uuid",
    "rating": 5,
    "comment": "Excellent service and comfortable bus",
    "created_at": "2026-08-20T15:00:00Z"
  }
}
```

---

### Admin Endpoints

All admin endpoints require `superadmin` or `operator` role.

#### GET /admin/dashboard

Get admin dashboard analytics.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total_bookings": 1500,
      "total_revenue": 1200000.00,
      "active_trips": 45,
      "active_users": 850
    },
    "today": {
      "bookings": 25,
      "revenue": 20000.00,
      "new_users": 12
    },
    "popular_routes": [
      {
        "origin": "Kabul",
        "destination": "Herat",
        "bookings": 450,
        "revenue": 360000.00
      }
    ],
    "recent_bookings": []
  }
}
```

---

#### GET /admin/trips

List all trips (admin view).

---

#### POST /admin/trips

Create a new trip (admin).

**Request:**
```json
{
  "route_id": "route-uuid",
  "bus_id": "bus-uuid",
  "departure_time": "2026-08-25T06:00:00Z",
  "arrival_time": "2026-08-25T14:00:00Z",
  "base_price": 800.00,
  "vip_price": 1200.00
}
```

---

#### PUT /admin/trips/:id

Update a trip (admin).

---

#### DELETE /admin/trips/:id

Cancel a trip (admin).

---

#### GET /admin/bookings

List all bookings (admin view).

---

#### GET /admin/users

List all users (admin view).

---

#### POST /admin/buses

Add a new bus (admin).

---

#### PUT /admin/buses/:id

Update bus details (admin).

---

### Health Check

#### GET /health

Server health check (no auth required).

**Response (200):**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime": 86400,
  "database": "connected",
  "redis": "connected",
  "timestamp": "2026-08-14T12:00:00Z"
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address"
      }
    ]
  }
}
```

### Error Codes

| HTTP Code | Error Code              | Description                          |
|-----------|-------------------------|--------------------------------------|
| 400       | VALIDATION_ERROR        | Request body validation failed       |
| 401       | UNAUTHORIZED            | Missing or invalid authentication    |
| 403       | FORBIDDEN               | Insufficient permissions             |
| 404       | NOT_FOUND               | Resource not found                   |
| 409       | CONFLICT                | Resource already exists              |
| 422       | UNPROCESSABLE           | Business logic error                 |
| 429       | RATE_LIMIT_EXCEEDED     | Too many requests                    |
| 500       | INTERNAL_ERROR          | Server error                         |
| 503       | SERVICE_UNAVAILABLE     | Service temporarily unavailable      |

---

## Rate Limits

- Authenticated users: 100 requests/minute
- Unauthenticated: 20 requests/minute
- Payment endpoints: 10 requests/minute
- Search endpoints: 30 requests/minute

Rate limit headers included in response:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1692014400
```

---

## Pagination

List endpoints support pagination:

```
GET /bookings?page=2&limit=10
```

Response includes:
```json
{
  "pagination": {
    "total": 150,
    "page": 2,
    "limit": 10,
    "total_pages": 15
  }
}
```

---

## Localization

All responses include the requested language. Pass the `Accept-Language` header:

```
Accept-Language: fa
Accept-Language: ps
Accept-Language: en
```

Supported languages: `en` (English), `fa` (Dari/Farsi), `ps` (Pashto)

---

## WebSocket Events (Real-time)

Connect to: `wss://api.afghango.app/ws`

### Seat Updates
```json
{
  "event": "seat_update",
  "data": {
    "trip_id": "trip-uuid",
    "seat_number": "A1",
    "status": "locked",
    "locked_by": "other-user-id"
  }
}
```

### Trip Status
```json
{
  "event": "trip_status",
  "data": {
    "trip_id": "trip-uuid",
    "status": "departed",
    "message": "Trip has departed"
  }
}
```
