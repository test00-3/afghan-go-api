import { Request, Response } from 'express';
import { notificationService } from '../services/notification.service';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ handler: 'notification' });

/**
 * GET /api/notifications
 * Get user's notifications
 */
export async function getUserNotifications(req: Request, res: Response): Promise<void> {
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

    const result = await notificationService.getUserNotifications(
      req.user.user_id,
      page,
      limit
    );

    res.status(200).json({
      success: true,
      data: result.notifications,
      unread_count: result.unreadCount,
    });
  } catch (error) {
    logger.error('Get notifications failed', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to fetch notifications.',
      },
    });
  }
}

/**
 * PATCH /api/notifications/:id/read
 * Mark notification as read
 */
export async function markAsRead(req: Request, res: Response): Promise<void> {
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

    await notificationService.markAsRead(id, req.user.user_id);

    res.status(200).json({
      success: true,
      message: 'Notification marked as read.',
    });
  } catch (error) {
    logger.error('Mark notification as read failed', {
      notificationId: req.params.id,
      error: (error as Error).message,
    });
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to mark notification as read.',
      },
    });
  }
}

/**
 * PATCH /api/notifications/read-all
 * Mark all notifications as read
 */
export async function markAllAsRead(req: Request, res: Response): Promise<void> {
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

    await notificationService.markAllAsRead(req.user.user_id);

    res.status(200).json({
      success: true,
      message: 'All notifications marked as read.',
    });
  } catch (error) {
    logger.error('Mark all notifications as read failed', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to mark notifications as read.',
      },
    });
  }
}
