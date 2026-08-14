import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),

  REDIS_URL: z.string().default('redis://localhost:6379'),

  JWT_SECRET: z.string().min(8),
  JWT_EXPIRY: z.string().default('30d'),

  HESABPAY_API_URL: z.string().default('https://api.hesabpay.com'),
  HESABPAY_MERCHANT_ID: z.string().default('demo'),
  HESABPAY_SECRET_KEY: z.string().default('demo'),
  HESABPAY_CALLBACK_URL: z.string().default('http://localhost:3000/api/payments/hesabpay/webhook'),

  MOMO_API_URL: z.string().default('https://api.momo.af'),
  MOMO_API_KEY: z.string().default('demo'),
  MOMO_MERCHANT_ID: z.string().default('demo'),
  MOMO_CALLBACK_URL: z.string().default('http://localhost:3000/api/payments/momo/webhook'),

  PAYPAL_CLIENT_ID: z.string().default('demo'),
  PAYPAL_CLIENT_SECRET: z.string().default('demo'),
  PAYPAL_MODE: z.enum(['sandbox', 'live']).default('sandbox'),

  FIREBASE_PROJECT_ID: z.string().default('demo'),
  FIREBASE_PRIVATE_KEY: z.string().default('demo'),
  FIREBASE_CLIENT_EMAIL: z.string().default('demo@demo.com'),

  SMS_PROVIDER: z.enum(['twilio', 'aws_sns', 'custom', 'console']).default('console'),
  TWILIO_ACCOUNT_SID: z.string().default('demo'),
  TWILIO_AUTH_TOKEN: z.string().default('demo'),
  TWILIO_PHONE_NUMBER: z.string().default('+93700123456'),

  RATE_LIMIT_WINDOW_MS: z.coerce.number().default(60000),
  RATE_LIMIT_MAX_REQUESTS: z.coerce.number().default(20),

  FRONTEND_URL: z.string().default('http://localhost:3000'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment variables:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const config = parsed.data;
