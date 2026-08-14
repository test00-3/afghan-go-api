import { z } from 'zod';

// ============ ENUMS ============

export enum UserRole {
  PASSENGER = 'passenger',
  DRIVER = 'driver',
  ADMIN = 'admin',
}

export enum BusType {
  VIP = 'vip',
  STANDARD = 'standard',
  ECONOMY = 'economy',
}

export enum BookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  PAID = 'paid',
  CANCELLED = 'cancelled',
  EXPIRED = 'expired',
}

export enum PaymentProvider {
  HESABPAY = 'hesabpay',
  MOMO = 'momo',
  PAYPAL = 'paypal',
  CASH = 'cash',
}

export enum PaymentStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  REFUNDED = 'refunded',
}

export enum TripStatus {
  SCHEDULED = 'scheduled',
  DEPARTED = 'departed',
  ARRIVED = 'arrived',
  CANCELLED = 'cancelled',
}

export enum NotificationType {
  BOOKING_CONFIRMED = 'booking_confirmed',
  PAYMENT_RECEIVED = 'payment_received',
  TRIP_UPDATE = 'trip_update',
  REMINDER = 'reminder',
  OTP = 'otp',
  CANCELLATION = 'cancellation',
}

export enum SeatStatus {
  AVAILABLE = 'available',
  LOCKED = 'locked',
  BOOKED = 'booked',
}

export enum Language {
  DARI = 'dari',
  PASHTO = 'pashto',
  ENGLISH = 'english',
}

// ============ DATABASE TYPES ============

export interface User {
  id: string;
  phone_number: string;
  full_name: string | null;
  role: UserRole;
  preferred_language: Language;
  fcm_token: string | null;
  created_at: string;
  updated_at: string;
}

export interface Company {
  id: string;
  name: string;
  name_ps: string;
  name_fa: string;
  phone: string;
  rating: number;
  created_at: string;
}

export interface Bus {
  id: string;
  company_id: string;
  plate_number: string;
  bus_type: BusType;
  total_seats: number;
  has_ac: boolean;
  has_wifi: boolean;
  has_usb: boolean;
  created_at: string;
}

export interface Trip {
  id: string;
  bus_id: string;
  company_id: string;
  origin: string;
  destination: string;
  departure_time: string;
  arrival_time: string;
  price: number;
  status: TripStatus;
  available_seats: number;
  created_at: string;
  updated_at: string;
}

export interface TripWithDetails extends Trip {
  bus: Bus;
  company: Company;
}

export interface Seat {
  id: string;
  trip_id: string;
  seat_number: string;
  row_number: number;
  column_number: number;
  status: SeatStatus;
  locked_by: string | null;
  locked_at: string | null;
}

export interface Booking {
  id: string;
  user_id: string;
  trip_id: string;
  seat_numbers: string[];
  total_price: number;
  deposit_amount: number;
  balance_amount: number;
  status: BookingStatus;
  payment_provider: PaymentProvider | null;
  payment_reference: string | null;
  idempotency_key: string | null;
  created_at: string;
  updated_at: string;
}

export interface BookingWithDetails extends Booking {
  trip: TripWithDetails;
}

export interface Payment {
  id: string;
  booking_id: string;
  user_id: string;
  provider: PaymentProvider;
  provider_reference: string | null;
  amount: number;
  currency: string;
  status: PaymentStatus;
  webhook_payload: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
}

export interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  title_fa: string;
  title_ps: string;
  body: string;
  body_fa: string;
  body_ps: string;
  data: Record<string, unknown> | null;
  is_read: boolean;
  created_at: string;
}

export interface Review {
  id: string;
  user_id: string;
  trip_id: string;
  booking_id: string;
  rating: number;
  comment: string | null;
  created_at: string;
}

export interface ReviewWithUser extends Review {
  user: Pick<User, 'id' | 'full_name' | 'phone_number'>;
}

export interface City {
  name: string;
  name_fa: string;
  name_ps: string;
  province: string;
}

// ============ REQUEST/RESPONSE TYPES ============

export interface OTPSendRequest {
  phone_number: string;
  language?: Language;
}

export interface OTPVerifyRequest {
  phone_number: string;
  otp: string;
}

export interface TripSearchParams {
  origin?: string;
  destination?: string;
  date?: string;
  bus_type?: BusType;
  min_price?: number;
  max_price?: number;
  page?: number;
  limit?: number;
}

export interface CreateBookingRequest {
  trip_id: string;
  seat_numbers: string[];
  payment_provider: PaymentProvider;
  idempotency_key?: string;
}

export interface CancelBookingRequest {
  reason?: string;
}

export interface CreateReviewRequest {
  trip_id: string;
  booking_id: string;
  rating: number;
  comment?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    total_pages: number;
  };
}

export interface AuthenticatedRequest extends Express.Request {
  user?: {
    id: string;
    phone_number: string;
    role: UserRole;
  };
}

// ============ ERROR CLASSES ============

export class AppError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
    public details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export class AuthError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(401, 'AUTH_ERROR', message, details);
    this.name = 'AuthError';
  }
}

export class TripError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(404, 'TRIP_ERROR', message, details);
    this.name = 'TripError';
  }
}

export class BookingError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(400, 'BOOKING_ERROR', message, details);
    this.name = 'BookingError';
  }
}

export class PaymentError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(400, 'PAYMENT_ERROR', message, details);
    this.name = 'PaymentError';
  }
}

export class SeatLockError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(409, 'SEAT_LOCK_ERROR', message, details);
    this.name = 'SeatLockError';
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string) {
    super(404, 'NOT_FOUND', `${resource} not found`);
    this.name = 'NotFoundError';
  }
}

export class RateLimitError extends AppError {
  constructor(message = 'Too many requests. Please try again later.') {
    super(429, 'RATE_LIMIT', message);
    this.name = 'RateLimitError';
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super(409, 'CONFLICT', message);
    this.name = 'ConflictError';
  }
}

export class ValidationError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(400, 'VALIDATION_ERROR', message, details);
    this.name = 'ValidationError';
  }
}

// ============ VALIDATION SCHEMAS ============

export const OTPSendSchema = z.object({
  phone_number: z.string().regex(/^\+93\d{9}$/, 'Invalid Afghan phone number format. Must be +93XXXXXXXXX'),
  language: z.nativeEnum(Language).optional().default(Language.DARI),
});

export const OTPVerifySchema = z.object({
  phone_number: z.string().regex(/^\+93\d{9}$/, 'Invalid Afghan phone number format'),
  otp: z.string().length(6, 'OTP must be 6 digits'),
});

export const TripSearchSchema = z.object({
  origin: z.string().optional(),
  destination: z.string().optional(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be YYYY-MM-DD format').optional(),
  bus_type: z.nativeEnum(BusType).optional(),
  min_price: z.coerce.number().min(0).optional(),
  max_price: z.coerce.number().min(0).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export const CreateBookingSchema = z.object({
  trip_id: z.string().uuid(),
  seat_numbers: z.array(z.string()).min(1, 'At least one seat required').max(10, 'Maximum 10 seats per booking'),
  payment_provider: z.nativeEnum(PaymentProvider),
  idempotency_key: z.string().uuid().optional(),
});

export const CreateReviewSchema = z.object({
  trip_id: z.string().uuid(),
  booking_id: z.string().uuid(),
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(500).optional(),
});

export const CancelBookingSchema = z.object({
  reason: z.string().max(200).optional(),
});

// ============ CONSTANTS ============

export const AFGHAN_CITIES: City[] = [
  { name: 'Kabul', name_fa: 'کابل', name_ps: 'کابل', province: 'Kabul' },
  { name: 'Mazar-i-Sharif', name_fa: 'مزار شریف', name_ps: 'مزار شریف', province: 'Balkh' },
  { name: 'Herat', name_fa: 'هرات', name_ps: 'هرات', province: 'Herat' },
  { name: 'Kandahar', name_fa: 'قندهار', name_ps: 'قندهار', province: 'Kandahar' },
  { name: 'Jalalabad', name_fa: 'جلال آباد', name_ps: 'جلال آباد', province: 'Nangarhar' },
  { name: 'Kunduz', name_fa: 'قندوز', name_ps: 'قندوز', province: 'Kunduz' },
  { name: 'Ghazni', name_fa: 'غزنی', name_ps: 'غزنی', province: 'Ghazni' },
  { name: 'Bamyan', name_fa: 'بامیان', name_ps: 'بامیان', province: 'Bamyan' },
  { name: 'Lashkar Gah', name_fa: 'لشکرگاه', name_ps: 'لشکرگاه', province: 'Helmand' },
  { name: 'Taloqan', name_fa: 'تالقان', name_ps: 'تالقان', province: 'Takhar' },
  { name: 'Sheberghan', name_fa: 'شبرغان', name_ps: 'شبرغان', province: 'Jowzjan' },
  { name: 'Mehtarlam', name_fa: 'چاریکار', name_ps: 'مهترلام', province: 'Laghman' },
  { name: 'Charikar', name_fa: 'چاریکار', name_ps: 'چاریکار', province: 'Parwan' },
  { name: 'Aybak', name_fa: 'ایبک', name_ps: 'ایبک', province: 'Samangan' },
  { name: 'Fayzabad', name_fa: 'فیض آباد', name_ps: 'فیض آباد', province: 'Badakhshan' },
  { name: 'Zaranj', name_fa: 'زرنج', name_ps: 'زرنج', province: 'Nimroz' },
  { name: 'Sharan', name_fa: 'شرن', name_ps: 'شرن', province: 'Paktika' },
  { name: 'Gardez', name_fa: 'گردیز', name_ps: 'گردیز', province: 'Paktia' },
  { name: 'Khost', name_fa: 'خوست', name_ps: 'خوست', province: 'Khost' },
  { name: 'Baghlan', name_fa: 'بغلان', name_ps: 'بغلان', province: 'Baghlan' },
  { name: 'Puli Khumri', name_fa: 'پل خمری', name_ps: 'پل خمری', province: 'Baghlan' },
  { name: 'Maymana', name_fa: 'میمنه', name_ps: 'میمنه', province: 'Faryab' },
  { name: 'Farah', name_fa: 'فراه', name_ps: 'فراه', province: 'Farah' },
  { name: 'Qala-i-Naw', name_fa: 'قلعه نو', name_ps: 'قلعه نو', province: 'Badghis' },
];

export const SEAT_LOCK_TTL_SECONDS = 900; // 15 minutes
export const OTP_TTL_SECONDS = 300; // 5 minutes
export const DEPOSIT_PERCENTAGE = 0.2; // 20%
export const BOOKING_EXPIRY_MINUTES = 30;
