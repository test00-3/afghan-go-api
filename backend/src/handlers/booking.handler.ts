import { Request, Response } from 'express';
import { bookingService } from '../services/booking.service';
import {
  CreateBookingSchema,
  CancelBookingSchema,
  BookingError,
  NotFoundError,
  ConflictError,
  SeatLockError,
  BookingStatus,
} from '../types';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ handler: 'booking' });

/**
 * POST /api/bookings
 * Create a new booking
 */
export async function createBooking(req: Request, res: Response): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: {
          code: 'AUTH_ERROR',
          message: 'Authentication required.',
        },
      });
      return;
    }

    const { trip_id, seat_numbers, payment_provider, idempotency_key } =
      CreateBookingSchema.parse(req.body);

    const result = await bookingService.createBooking(
      req.user.user_id,
      trip_id,
      seat_numbers,
      payment_provider,
      idempotency_key
    );

    res.status(201).json({
      success: true,
      data: {
        booking: result.booking,
        payment_url: result.paymentUrl,
      },
    });
  } catch (error) {
    if (error instanceof BookingError || error instanceof SeatLockError || error instanceof ConflictError) {
      res.status(error.statusCode).json({
        success: false,
        error: {
          code: error.code,
          message: error.message,
        },
      });
    } else {
      logger.error('Create booking failed', { error: (error as Error).message });
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to create booking.',
        },
      });
    }
  }
}

/**
 * GET /api/bookings
 * List user's bookings
 */
export async function getUserBookings(req: Request, res: Response): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: {
          code: 'AUTH_ERROR',
          message: 'Authentication required.',
        },
      });
      return;
    }

    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const status = req.query.status as BookingStatus | undefined;

    const result = await bookingService.getUserBookings(
      req.user.user_id,
      page,
      limit,
      status
    );

    res.status(200).json({
      success: true,
      data: result.data,
      pagination: result.pagination,
    });
  } catch (error) {
    logger.error('Get bookings failed', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to fetch bookings.',
      },
    });
  }
}

/**
 * GET /api/bookings/:id
 * Get booking detail
 */
export async function getBookingById(req: Request, res: Response): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: {
          code: 'AUTH_ERROR',
          message: 'Authentication required.',
        },
      });
      return;
    }

    const { id } = req.params;

    const booking = await bookingService.getBookingById(id);

    // Verify ownership
    if (booking.user_id !== req.user.user_id) {
      res.status(403).json({
        success: false,
        error: {
          code: 'FORBIDDEN',
          message: 'You do not have access to this booking.',
        },
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: booking,
    });
  } catch (error) {
    if (error instanceof NotFoundError) {
      res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Booking not found.',
        },
      });
    } else {
      logger.error('Get booking failed', { bookingId: req.params.id, error: (error as Error).message });
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get booking details.',
        },
      });
    }
  }
}

/**
 * PATCH /api/bookings/:id/cancel
 * Cancel booking
 */
export async function cancelBooking(req: Request, res: Response): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: {
          code: 'AUTH_ERROR',
          message: 'Authentication required.',
        },
      });
      return;
    }

    const { id } = req.params;
    const { reason } = CancelBookingSchema.parse(req.body);

    const booking = await bookingService.cancelBooking(
      req.user.user_id,
      id,
      reason
    );

    res.status(200).json({
      success: true,
      data: booking,
    });
  } catch (error) {
    if (error instanceof BookingError) {
      res.status(error.statusCode).json({
        success: false,
        error: {
          code: error.code,
          message: error.message,
        },
      });
    } else if (error instanceof NotFoundError) {
      res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Booking not found.',
        },
      });
    } else {
      logger.error('Cancel booking failed', { bookingId: req.params.id, error: (error as Error).message });
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to cancel booking.',
        },
      });
    }
  }
}
