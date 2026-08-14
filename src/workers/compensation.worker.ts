import cron from 'node-cron';
import { seatService } from '../services/seat.service';
import { bookingService } from '../services/booking.service';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ worker: 'compensation' });

/**
 * Compensation worker
 * Handles cleanup of stale bookings and expired seat locks
 */

// Release expired seat locks every 2 minutes
cron.schedule('*/2 * * * *', async () => {
  try {
    const released = await seatService.releaseExpiredLocks();
    if (released > 0) {
      logger.info('Released expired seat locks', { count: released });
    }
  } catch (error) {
    logger.error('Failed to release expired seat locks', {
      error: (error as Error).message,
    });
  }
});

// Expire pending bookings every 5 minutes
cron.schedule('*/5 * * * *', async () => {
  try {
    const expired = await bookingService.expirePendingBookings();
    if (expired > 0) {
      logger.info('Expired pending bookings', { count: expired });
    }
  } catch (error) {
    logger.error('Failed to expire pending bookings', {
      error: (error as Error).message,
    });
  }
});

// Run immediately on startup
async function runInitialCleanup() {
  logger.info('Running initial cleanup...');

  try {
    const releasedLocks = await seatService.releaseExpiredLocks();
    logger.info('Initial seat lock cleanup', { released: releasedLocks });
  } catch (error) {
    logger.error('Initial seat lock cleanup failed', {
      error: (error as Error).message,
    });
  }

  try {
    const expiredBookings = await bookingService.expirePendingBookings();
    logger.info('Initial booking cleanup', { expired: expiredBookings });
  } catch (error) {
    logger.error('Initial booking cleanup failed', {
      error: (error as Error).message,
    });
  }
}

// Run on startup
runInitialCleanup();

logger.info('Compensation worker started');

// Keep the process alive
process.on('SIGINT', () => {
  logger.info('Compensation worker shutting down');
  process.exit(0);
});

process.on('SIGTERM', () => {
  logger.info('Compensation worker shutting down');
  process.exit(0);
});
