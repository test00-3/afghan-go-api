import { v4 as uuidv4 } from 'uuid';
import { supabase } from '../db/connection';
import { redis } from '../db/connection';
import {
  Booking,
  BookingWithDetails,
  BookingStatus,
  PaymentProvider,
  TripWithDetails,
  PaginatedResponse,
  BookingError,
  NotFoundError,
  ConflictError,
  DEPOSIT_PERCENTAGE,
} from '../types';
import { createContextLogger } from '../utils/logger';
import { seatService } from './seat.service';
import { tripService } from './trip.service';
import { paymentService } from './payment.service';
import { notificationService } from './notification.service';
import { BOOKING_CONFIRMED_MESSAGES, BOOKING_CANCELLED_MESSAGES, getMessage } from '../utils/messages';

const logger = createContextLogger({ service: 'booking' });

export class BookingService {
  /**
   * Create a new booking (CRITICAL - atomic operation)
   */
  async createBooking(
    userId: string,
    tripId: string,
    seatNumbers: string[],
    paymentProvider: PaymentProvider,
    idempotencyKey?: string
  ): Promise<{ booking: BookingWithDetails; paymentUrl?: string }> {
    // Check idempotency
    if (idempotencyKey) {
      const existingBooking = await this.findByIdempotencyKey(idempotencyKey);
      if (existingBooking) {
        logger.info('Idempotent booking request', { idempotencyKey, bookingId: existingBooking.id });
        return { booking: existingBooking };
      }
    }

    // Get trip details
    const trip = await tripService.getTripById(tripId);

    // Validate trip is bookable
    if (trip.status !== 'scheduled') {
      throw new BookingError('This trip is no longer available for booking.');
    }

    if (new Date(trip.departure_time) <= new Date()) {
      throw new BookingError('This trip has already departed.');
    }

    // Validate seat count
    if (seatNumbers.length > 10) {
      throw new BookingError('Maximum 10 seats per booking.');
    }

    // Check user doesn't already have an active booking for this trip
    const existingBooking = await this.getActiveBookingForTrip(userId, tripId);
    if (existingBooking) {
      throw new ConflictError('You already have an active booking for this trip.');
    }

    // Calculate prices
    const totalPrice = trip.price * seatNumbers.length;
    const depositAmount = Math.round(totalPrice * DEPOSIT_PERCENTAGE);
    const balanceAmount = totalPrice - depositAmount;

    // Lock seats
    await seatService.lockSeats(tripId, seatNumbers, userId);

    // Create booking in transaction
    try {
      const bookingId = uuidv4();
      const bookingRef = `BK${Date.now().toString(36).toUpperCase()}`;

      const { data: booking, error: bookingError } = await supabase
        .from('bookings')
        .insert({
          id: bookingId,
          user_id: userId,
          trip_id: tripId,
          seat_numbers: seatNumbers,
          total_price: totalPrice,
          deposit_amount: depositAmount,
          balance_amount: balanceAmount,
          status: BookingStatus.PENDING,
          payment_provider: paymentProvider,
          idempotency_key: idempotencyKey || null,
          booking_ref: bookingRef,
        })
        .select()
        .single();

      if (bookingError) {
        // Release seats on failure
        await seatService.releaseSeats(tripId, seatNumbers);
        throw new BookingError('Failed to create booking record.');
      }

      // Store idempotency key mapping
      if (idempotencyKey) {
        await redis.set(`idempotency:${idempotencyKey}`, bookingId, 'EX', 86400); // 24 hours
      }

      // Initiate payment
      let paymentUrl: string | undefined;

      if (paymentProvider === PaymentProvider.HESABPAY) {
        const result = await paymentService.createHesabPayPayment(
          bookingId,
          depositAmount,
          `Booking ${bookingRef} - ${trip.origin} to ${trip.destination}`
        );
        paymentUrl = result.paymentUrl;
      } else if (paymentProvider === PaymentProvider.MOMO) {
        const result = await paymentService.createMoMoPayment(
          bookingId,
          depositAmount,
          `Booking ${bookingRef}`
        );
        paymentUrl = result.paymentUrl;
      } else if (paymentProvider === PaymentProvider.PAYPAL) {
        const result = await paymentService.createPayPalOrder(
          bookingId,
          depositAmount,
          `Booking ${bookingRef} - ${trip.origin} to ${trip.destination}`
        );
        paymentUrl = result.approvalUrl;
      }
      // For CASH payments, no URL needed

      // Fetch complete booking with details
      const fullBooking = await this.getBookingById(bookingId);

      logger.info('Booking created', {
        bookingId,
        userId,
        tripId,
        seats: seatNumbers,
        totalPrice,
        deposit: depositAmount,
      });

      return { booking: fullBooking, paymentUrl };
    } catch (error) {
      // If booking creation fails, release seats
      if (!(error instanceof BookingError)) {
        await seatService.releaseSeats(tripId, seatNumbers);
      }
      throw error;
    }
  }

  /**
   * Get booking by ID with full details
   */
  async getBookingById(bookingId: string): Promise<BookingWithDetails> {
    const { data, error } = await supabase
      .from('bookings')
      .select(
        `
        *,
        trip:trips(
          *,
          bus:buses(*),
          company:companies(*)
        )
        `
      )
      .eq('id', bookingId)
      .single();

    if (error || !data) {
      throw new NotFoundError('Booking');
    }

    return data as BookingWithDetails;
  }

  /**
   * Get user's bookings
   */
  async getUserBookings(
    userId: string,
    page: number = 1,
    limit: number = 20,
    status?: BookingStatus
  ): Promise<PaginatedResponse<BookingWithDetails>> {
    let query = supabase
      .from('bookings')
      .select(
        `
        *,
        trip:trips(
          *,
          bus:buses(*),
          company:companies(*)
        )
        `,
        { count: 'exact' }
      )
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }

    const offset = (page - 1) * limit;
    query = query.range(offset, offset + limit - 1);

    const { data, error, count } = await query;

    if (error) {
      throw new BookingError('Failed to fetch bookings.');
    }

    return {
      data: (data || []) as BookingWithDetails[],
      pagination: {
        page,
        limit,
        total: count || 0,
        total_pages: Math.ceil((count || 0) / limit),
      },
    };
  }

  /**
   * Cancel booking
   */
  async cancelBooking(
    userId: string,
    bookingId: string,
    reason?: string
  ): Promise<BookingWithDetails> {
    const booking = await this.getBookingById(bookingId);

    // Verify ownership
    if (booking.user_id !== userId) {
      throw new BookingError('You can only cancel your own bookings.');
    }

    // Check if booking can be cancelled
    if (booking.status === BookingStatus.CANCELLED) {
      throw new BookingError('Booking is already cancelled.');
    }

    if (booking.status === BookingStatus.PAID) {
      throw new BookingError('Paid bookings cannot be cancelled. Please contact support for refunds.');
    }

    // Cancel booking
    const { error } = await supabase
      .from('bookings')
      .update({
        status: BookingStatus.CANCELLED,
        updated_at: new Date().toISOString(),
      })
      .eq('id', bookingId);

    if (error) {
      throw new BookingError('Failed to cancel booking.');
    }

    // Release seats
    await seatService.releaseSeats(booking.trip_id, booking.seat_numbers);

    // Send cancellation notification
    try {
      const trip = booking.trip as TripWithDetails;
      const template = BOOKING_CANCELLED_MESSAGES;
      const { body, body_fa, body_ps } = getMessage(template, 'dari' as any, {
        bookingRef: booking.id.slice(0, 8).toUpperCase(),
        origin: trip.origin,
        destination: trip.destination,
      });

      await notificationService.createNotification(
        userId,
        'cancellation' as any,
        body,
        body_fa,
        body_ps,
        { booking_id: bookingId }
      );
    } catch (notifError) {
      logger.error('Failed to send cancellation notification', { error: (notifError as Error).message });
    }

    logger.info('Booking cancelled', { bookingId, userId, reason });
    return this.getBookingById(bookingId);
  }

  /**
   * Confirm booking (after successful payment)
   */
  async confirmBooking(bookingId: string, paymentReference: string): Promise<BookingWithDetails> {
    const booking = await this.getBookingById(bookingId);

    if (booking.status !== BookingStatus.PENDING) {
      throw new BookingError(`Booking is in ${booking.status} state, cannot confirm.`);
    }

    // Update booking status
    const { error } = await supabase
      .from('bookings')
      .update({
        status: BookingStatus.CONFIRMED,
        payment_reference: paymentReference,
        updated_at: new Date().toISOString(),
      })
      .eq('id', bookingId);

    if (error) {
      throw new BookingError('Failed to confirm booking.');
    }

    // Confirm seats
    await seatService.confirmSeats(booking.trip_id, booking.seat_numbers, booking.user_id);

    // Send confirmation notification
    try {
      const trip = booking.trip as TripWithDetails;
      const template = BOOKING_CONFIRMED_MESSAGES;
      const { body, body_fa, body_ps } = getMessage(template, 'dari' as any, {
        origin: trip.origin,
        destination: trip.destination,
        company: trip.company?.name || 'Unknown',
        seats: booking.seat_numbers.join(', '),
        balance: booking.balance_amount.toString(),
        bookingRef: booking.id.slice(0, 8).toUpperCase(),
      });

      await notificationService.createNotification(
        booking.user_id,
        'booking_confirmed' as any,
        body,
        body_fa,
        body_ps,
        { booking_id: bookingId }
      );
    } catch (notifError) {
      logger.error('Failed to send booking confirmation notification', { error: (notifError as Error).message });
    }

    logger.info('Booking confirmed', { bookingId });
    return this.getBookingById(bookingId);
  }

  /**
   * Get active booking for a trip
   */
  private async getActiveBookingForTrip(
    userId: string,
    tripId: string
  ): Promise<BookingWithDetails | null> {
    const { data, error } = await supabase
      .from('bookings')
      .select('id')
      .eq('user_id', userId)
      .eq('trip_id', tripId)
      .in('status', [BookingStatus.PENDING, BookingStatus.CONFIRMED, BookingStatus.PAID])
      .single();

    if (error || !data) {
      return null;
    }

    return this.getBookingById(data.id);
  }

  /**
   * Find booking by idempotency key
   */
  private async findByIdempotencyKey(idempotencyKey: string): Promise<BookingWithDetails | null> {
    const bookingId = await redis.get(`idempotency:${idempotencyKey}`);
    if (!bookingId) {
      return null;
    }

    try {
      return await this.getBookingById(bookingId);
    } catch {
      return null;
    }
  }

  /**
   * Expire old pending bookings (called by worker)
   */
  async expirePendingBookings(): Promise<number> {
    const expiryTime = new Date(Date.now() - 30 * 60 * 1000).toISOString(); // 30 minutes

    const { data, error } = await supabase
      .from('bookings')
      .update({
        status: BookingStatus.EXPIRED,
        updated_at: new Date().toISOString(),
      })
      .eq('status', BookingStatus.PENDING)
      .lt('created_at', expiryTime)
      .select('id, trip_id, seat_numbers');

    if (error) {
      logger.error('Failed to expire bookings', { error: error.message });
      return 0;
    }

    const expiredBookings = data || [];

    // Release seats for expired bookings
    for (const booking of expiredBookings) {
      try {
        await seatService.releaseSeats(booking.trip_id, booking.seat_numbers);
      } catch (err) {
        logger.error('Failed to release seats for expired booking', {
          bookingId: booking.id,
          error: (err as Error).message,
        });
      }
    }

    if (expiredBookings.length > 0) {
      logger.info('Expired pending bookings', { count: expiredBookings.length });
    }

    return expiredBookings.length;
  }
}

export const bookingService = new BookingService();
