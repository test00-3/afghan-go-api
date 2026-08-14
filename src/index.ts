import express from 'express';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { config } from './config';
import { redis } from './db/connection';
import { authenticate, optionalAuth } from './middleware/auth';
import { validate } from './middleware/validation';
import {
  OTPSendSchema,
  OTPVerifySchema,
  TripSearchSchema,
  CreateBookingSchema,
  CreateReviewSchema,
  CancelBookingSchema,
} from './types';

// Handlers
import { sendOTP, verifyOTP, getMe } from './handlers/auth.handler';
import { searchTrips, getTripById, getCities, getPopularRoutes } from './handlers/trip.handler';
import {
  createBooking,
  getUserBookings,
  getBookingById,
  cancelBooking,
} from './handlers/booking.handler';
import {
  hesabpayWebhook,
  momoWebhook,
  getPaymentStatus,
} from './handlers/payment.handler';
import {
  getUserNotifications,
  markAsRead,
  markAllAsRead,
} from './handlers/notification.handler';
import { createReview, getTripReviews } from './handlers/review.handler';

import { createContextLogger } from './utils/logger';

const logger = createContextLogger({ service: 'api' });

const app = express();

// ============ MIDDLEWARE ============

// CORS
app.use(
  cors({
    origin: config.FRONTEND_URL,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Idempotency-Key'],
  })
);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Trust proxy for rate limiting
app.set('trust proxy', 1);

// Rate limiting
const globalLimiter = rateLimit({
  windowMs: config.RATE_LIMIT_WINDOW_MS,
  max: config.RATE_LIMIT_MAX_REQUESTS * 10,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMIT',
      message: 'Too many requests. Please try again later.',
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiter = rateLimit({
  windowMs: config.RATE_LIMIT_WINDOW_MS,
  max: config.RATE_LIMIT_MAX_REQUESTS,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMIT',
      message: 'Too many OTP requests. Please wait before trying again.',
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const bookingLimiter = rateLimit({
  windowMs: 60000, // 1 minute
  max: 5,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMIT',
      message: 'Too many booking requests. Please try again later.',
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use(globalLimiter);

// ============ HEALTH CHECK ============

app.get('/health', async (req, res) => {
  try {
    // Check Redis connection
    await redis.ping();

    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        redis: 'connected',
      },
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: (error as Error).message,
    });
  }
});

// ============ AUTH ROUTES ============

app.post(
  '/api/auth/otp/send',
  authLimiter,
  validate(OTPSendSchema, 'body'),
  sendOTP
);

app.post(
  '/api/auth/otp/verify',
  authLimiter,
  validate(OTPVerifySchema, 'body'),
  verifyOTP
);

app.get('/api/auth/me', authenticate, getMe);

// ============ TRIP ROUTES ============

app.get(
  '/api/trips',
  optionalAuth,
  validate(TripSearchSchema, 'query'),
  searchTrips
);

app.get('/api/trips/popular-routes', optionalAuth, getPopularRoutes);

app.get('/api/trips/:id', optionalAuth, getTripById);

app.get('/api/cities', optionalAuth, getCities);

// ============ BOOKING ROUTES ============

app.post(
  '/api/bookings',
  authenticate,
  bookingLimiter,
  validate(CreateBookingSchema, 'body'),
  createBooking
);

app.get('/api/bookings', authenticate, getUserBookings);

app.get('/api/bookings/:id', authenticate, getBookingById);

app.patch(
  '/api/bookings/:id/cancel',
  authenticate,
  validate(CancelBookingSchema, 'body'),
  cancelBooking
);

// ============ PAYMENT ROUTES (Webhooks - no auth) ============

app.post('/api/payments/hesabpay/webhook', express.raw({ type: 'application/json' }), hesabpayWebhook);

app.post('/api/payments/momo/webhook', express.raw({ type: 'application/json' }), momoWebhook);

app.get('/api/payments/:bookingId/status', authenticate, getPaymentStatus);

// ============ NOTIFICATION ROUTES ============

app.get('/api/notifications', authenticate, getUserNotifications);

app.patch('/api/notifications/:id/read', authenticate, markAsRead);

app.patch('/api/notifications/read-all', authenticate, markAllAsRead);

// ============ REVIEW ROUTES ============

app.post(
  '/api/reviews',
  authenticate,
  validate(CreateReviewSchema, 'body'),
  createReview
);

app.get('/api/trips/:id/reviews', optionalAuth, getTripReviews);

// ============ 404 HANDLER ============

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.path} not found.`,
    },
  });
});

// ============ ERROR HANDLER ============

app.use(
  (
    err: Error,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) => {
    logger.error('Unhandled error', {
      error: err.message,
      stack: err.stack,
      path: req.path,
      method: req.method,
    });

    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message:
          config.NODE_ENV === 'production'
            ? 'Internal server error.'
            : err.message,
      },
    });
  }
);

// ============ START SERVER ============

async function startServer() {
  try {
    // Test Redis connection
    await redis.ping();
    logger.info('Redis connected');

    app.listen(config.PORT, () => {
      logger.info(`Server running on port ${config.PORT}`, {
        env: config.NODE_ENV,
        port: config.PORT,
      });
    });
  } catch (error) {
    logger.error('Failed to start server', { error: (error as Error).message });
    process.exit(1);
  }
}

startServer();

export default app;
