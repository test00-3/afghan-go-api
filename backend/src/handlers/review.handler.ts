import { Request, Response } from 'express';
import { reviewService } from '../services/review.service';
import { CreateReviewSchema, BookingError, NotFoundError, ValidationError } from '../types';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ handler: 'review' });

/**
 * POST /api/reviews
 * Submit a review
 */
export async function createReview(req: Request, res: Response): Promise<void> {
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

    const { trip_id, booking_id, rating, comment } = CreateReviewSchema.parse(req.body);

    const review = await reviewService.createReview(
      req.user.user_id,
      trip_id,
      booking_id,
      rating,
      comment
    );

    res.status(201).json({
      success: true,
      data: review,
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
          message: error.message,
        },
      });
    } else if (error instanceof ValidationError) {
      res.status(400).json({
        success: false,
        error: {
          code: error.code,
          message: error.message,
        },
      });
    } else {
      logger.error('Create review failed', { error: (error as Error).message });
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to create review.',
        },
      });
    }
  }
}

/**
 * GET /api/trips/:id/reviews
 * Get reviews for a trip
 */
export async function getTripReviews(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;

    const result = await reviewService.getTripReviews(id, page, limit);

    res.status(200).json({
      success: true,
      data: result.reviews,
      meta: {
        average_rating: result.averageRating,
        total_reviews: result.totalReviews,
      },
    });
  } catch (error) {
    logger.error('Get trip reviews failed', {
      tripId: req.params.id,
      error: (error as Error).message,
    });
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to fetch reviews.',
      },
    });
  }
}
