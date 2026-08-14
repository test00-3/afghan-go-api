import { supabase } from '../db/connection';
import { redis, acquireLock, releaseLock } from '../db/connection';
import {
  Seat,
  SeatStatus,
  SeatLockError,
  SEAT_LOCK_TTL_SECONDS,
} from '../types';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ service: 'seat' });

export class SeatService {
  /**
   * Get all seats for a trip
   */
  async getSeatsByTrip(tripId: string): Promise<Seat[]> {
    const { data, error } = await supabase
      .from('seats')
      .select('*')
      .eq('trip_id', tripId)
      .order('row_number')
      .order('column_number');

    if (error) {
      throw new SeatLockError('Failed to fetch seats.');
    }

    return (data || []) as Seat[];
  }

  /**
   * Check if seats are available
   */
  async checkSeatAvailability(tripId: string, seatNumbers: string[]): Promise<boolean> {
    const { data, error } = await supabase
      .from('seats')
      .select('seat_number, status')
      .eq('trip_id', tripId)
      .in('seat_number', seatNumbers);

    if (error) {
      throw new SeatLockError('Failed to check seat availability.');
    }

    const seats = data || [];

    // All requested seats must exist and be available
    if (seats.length !== seatNumbers.length) {
      return false;
    }

    return seats.every((seat) => seat.status === SeatStatus.AVAILABLE);
  }

  /**
   * Acquire seat locks for a user
   * Uses Redis for fast distributed locking and Supabase for persistence
   */
  async lockSeats(
    tripId: string,
    seatNumbers: string[],
    userId: string
  ): Promise<boolean> {
    // First, check availability in database
    const { data: seats, error: fetchError } = await supabase
      .from('seats')
      .select('seat_number, status')
      .eq('trip_id', tripId)
      .in('seat_number', seatNumbers);

    if (fetchError) {
      throw new SeatLockError('Failed to check seat status.');
    }

    if (!seats || seats.length !== seatNumbers.length) {
      throw new SeatLockError('One or more seats not found.');
    }

    // Check for already booked or locked seats
    const unavailableSeats = seats.filter(
      (s) => s.status !== SeatStatus.AVAILABLE
    );
    if (unavailableSeats.length > 0) {
      throw new SeatLockError(
        `Seats ${unavailableSeats.map((s) => s.seat_number).join(', ')} are not available.`
      );
    }

    // Acquire locks in Redis
    const lockOwner = `${userId}:${Date.now()}`;
    const lockedSeats: string[] = [];

    try {
      for (const seatNumber of seatNumbers) {
        const lockKey = `seat:${tripId}:${seatNumber}`;
        const acquired = await acquireLock(lockKey, SEAT_LOCK_TTL_SECONDS, lockOwner);

        if (!acquired) {
          // Release any seats we already locked
          for (const locked of lockedSeats) {
            const lockKey = `seat:${tripId}:${locked}`;
            await releaseLock(lockKey, lockOwner);
          }
          throw new SeatLockError(
            `Seat ${seatNumber} is currently locked by another user. Please try again.`
          );
        }
        lockedSeats.push(seatNumber);
      }

      // Update seat status in database
      const { error: updateError } = await supabase
        .from('seats')
        .update({
          status: SeatStatus.LOCKED,
          locked_by: userId,
          locked_at: new Date().toISOString(),
        })
        .eq('trip_id', tripId)
        .in('seat_number', seatNumbers);

      if (updateError) {
        // Release all locks on failure
        for (const locked of lockedSeats) {
          const lockKey = `seat:${tripId}:${locked}`;
          await releaseLock(lockKey, lockOwner);
        }
        throw new SeatLockError('Failed to lock seats in database.');
      }

      logger.info('Seats locked', { tripId, seatNumbers, userId });
      return true;
    } catch (error) {
      // Re-throw SeatLockError, wrap others
      if (error instanceof SeatLockError) {
        throw error;
      }
      throw new SeatLockError('Failed to lock seats. Please try again.');
    }
  }

  /**
   * Release seat locks (when booking is cancelled or expires)
   */
  async releaseSeats(tripId: string, seatNumbers: string[]): Promise<void> {
    const { error } = await supabase
      .from('seats')
      .update({
        status: SeatStatus.AVAILABLE,
        locked_by: null,
        locked_at: null,
      })
      .eq('trip_id', tripId)
      .in('seat_number', seatNumbers);

    if (error) {
      logger.error('Failed to release seats in DB', { tripId, seatNumbers, error: error.message });
    }

    // Also release Redis locks
    for (const seatNumber of seatNumbers) {
      const lockKey = `seat:${tripId}:${seatNumber}`;
      await redis.del(lockKey);
    }

    logger.info('Seats released', { tripId, seatNumbers });
  }

  /**
   * Confirm seat booking (after payment)
   */
  async confirmSeats(tripId: string, seatNumbers: string[], userId: string): Promise<void> {
    const { error } = await supabase
      .from('seats')
      .update({
        status: SeatStatus.BOOKED,
        locked_by: userId,
      })
      .eq('trip_id', tripId)
      .in('seat_number', seatNumbers);

    if (error) {
      throw new SeatLockError('Failed to confirm seats.');
    }

    // Update available seats count on trip
    const { data: trip, error: tripError } = await supabase
      .from('trips')
      .select('available_seats')
      .eq('id', tripId)
      .single();

    if (!tripError && trip) {
      await supabase
        .from('trips')
        .update({
          available_seats: trip.available_seats - seatNumbers.length,
          updated_at: new Date().toISOString(),
        })
        .eq('id', tripId);
    }

    logger.info('Seats confirmed', { tripId, seatNumbers, userId });
  }

  /**
   * Release expired locks (called by worker)
   */
  async releaseExpiredLocks(): Promise<number> {
    const expiryTime = new Date(Date.now() - SEAT_LOCK_TTL_SECONDS * 1000).toISOString();

    const { data, error } = await supabase
      .from('seats')
      .update({
        status: SeatStatus.AVAILABLE,
        locked_by: null,
        locked_at: null,
      })
      .eq('status', SeatStatus.LOCKED)
      .lt('locked_at', expiryTime)
      .select('seat_number, trip_id');

    if (error) {
      logger.error('Failed to release expired locks', { error: error.message });
      return 0;
    }

    const releasedCount = (data || []).length;
    if (releasedCount > 0) {
      logger.info('Released expired seat locks', { count: releasedCount });
    }

    return releasedCount;
  }

  /**
   * Get locked seats for a user (for cleanup)
   */
  async getLockedSeatsForUser(userId: string): Promise<Array<{ trip_id: string; seat_number: string }>> {
    const { data, error } = await supabase
      .from('seats')
      .select('trip_id, seat_number')
      .eq('locked_by', userId)
      .eq('status', SeatStatus.LOCKED);

    if (error) {
      return [];
    }

    return data || [];
  }
}

export const seatService = new SeatService();
