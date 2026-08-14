import { Request, Response } from 'express';
import { tripService } from '../services/trip.service';
import { TripSearchSchema, TripError, NotFoundError } from '../types';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ handler: 'trip' });

/**
 * GET /api/trips
 * Search trips with filters
 */
export async function searchTrips(req: Request, res: Response): Promise<void> {
  try {
    const params = TripSearchSchema.parse(req.query);

    const result = await tripService.searchTrips(params);

    res.status(200).json({
      success: true,
      data: result.data,
      pagination: result.pagination,
    });
  } catch (error) {
    if (error instanceof TripError) {
      res.status(error.statusCode).json({
        success: false,
        error: {
          code: error.code,
          message: error.message,
        },
      });
    } else {
      logger.error('Search trips failed', { error: (error as Error).message });
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to search trips.',
        },
      });
    }
  }
}

/**
 * GET /api/trips/:id
 * Get trip detail with seat map
 */
export async function getTripById(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    const seatMap = await tripService.getSeatMap(id);

    res.status(200).json({
      success: true,
      data: seatMap,
    });
  } catch (error) {
    if (error instanceof NotFoundError) {
      res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Trip not found.',
        },
      });
    } else {
      logger.error('Get trip failed', { tripId: req.params.id, error: (error as Error).message });
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to get trip details.',
        },
      });
    }
  }
}

/**
 * GET /api/cities
 * List of Afghan cities
 */
export async function getCities(req: Request, res: Response): Promise<void> {
  try {
    const cities = tripService.getCities();

    res.status(200).json({
      success: true,
      data: cities,
    });
  } catch (error) {
    logger.error('Get cities failed', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get cities.',
      },
    });
  }
}

/**
 * GET /api/trips/popular-routes
 * Get popular routes
 */
export async function getPopularRoutes(req: Request, res: Response): Promise<void> {
  try {
    const routes = await tripService.getPopularRoutes();

    res.status(200).json({
      success: true,
      data: routes,
    });
  } catch (error) {
    logger.error('Get popular routes failed', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get popular routes.',
      },
    });
  }
}
