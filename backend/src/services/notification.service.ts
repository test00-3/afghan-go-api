import { v4 as uuidv4 } from 'uuid';
import { supabase } from '../db/connection';
import { config } from '../config';
import {
  Notification,
  NotificationType,
  User,
} from '../types';
import { createContextLogger } from '../utils/logger';
import { retryNotification } from '../utils/retry';

const logger = createContextLogger({ service: 'notification' });

// Firebase Admin initialization (lazy)
let firebaseInitialized = false;
let firebaseApp: any = null;
let messaging: any = null;

async function initializeFirebase() {
  if (firebaseInitialized) return;

  try {
    const admin = await import('firebase-admin');
    
    if (!admin.apps.length) {
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: config.FIREBASE_PROJECT_ID,
          privateKey: config.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          clientEmail: config.FIREBASE_CLIENT_EMAIL,
        }),
      });
    } else {
      firebaseApp = admin.apps[0];
    }

    messaging = firebaseApp.messaging();
    firebaseInitialized = true;
    logger.info('Firebase initialized successfully');
  } catch (error) {
    logger.error('Failed to initialize Firebase', { error: (error as Error).message });
  }
}

export class NotificationService {
  /**
   * Create an in-app notification
   */
  async createNotification(
    userId: string,
    type: NotificationType,
    title: string,
    titleFa: string,
    titlePs: string,
    data?: Record<string, unknown>
  ): Promise<Notification> {
    // Get user language for appropriate body
    const { data: user } = await supabase
      .from('users')
      .select('preferred_language')
      .eq('id', userId)
      .single();

    const { data: notification, error } = await supabase
      .from('notifications')
      .insert({
        user_id: userId,
        type,
        title,
        title_fa: titleFa,
        title_ps: titlePs,
        body: title,
        body_fa: titleFa,
        body_ps: titlePs,
        data: data || null,
        is_read: false,
      })
      .select()
      .single();

    if (error) {
      logger.error('Failed to create notification', { userId, type, error: error.message });
      throw new Error('Failed to create notification.');
    }

    // Send FCM push notification
    try {
      await this.sendFCMNotification(userId, title, titleFa, data);
    } catch (fcmError) {
      logger.warn('FCM notification failed (non-critical)', {
        userId,
        error: (fcmError as Error).message,
      });
    }

    return notification as Notification;
  }

  /**
   * Get user notifications
   */
  async getUserNotifications(
    userId: string,
    page: number = 1,
    limit: number = 20
  ): Promise<{ notifications: Notification[]; unreadCount: number }> {
    const offset = (page - 1) * limit;

    const { data: notifications, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      throw new Error('Failed to fetch notifications.');
    }

    // Get unread count
    const { count: unreadCount } = await supabase
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_read', false);

    return {
      notifications: (notifications || []) as Notification[],
      unreadCount: unreadCount || 0,
    };
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId: string, userId: string): Promise<void> {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', notificationId)
      .eq('user_id', userId);

    if (error) {
      throw new Error('Failed to mark notification as read.');
    }
  }

  /**
   * Mark all user notifications as read
   */
  async markAllAsRead(userId: string): Promise<void> {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('user_id', userId)
      .eq('is_read', false);

    if (error) {
      throw new Error('Failed to mark notifications as read.');
    }
  }

  /**
   * Send FCM push notification
   */
  async sendFCMNotification(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, unknown>
  ): Promise<void> {
    await initializeFirebase();

    if (!messaging) {
      logger.warn('Firebase not initialized, skipping FCM');
      return;
    }

    // Get user's FCM token
    const { data: user } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('id', userId)
      .single();

    if (!user?.fcm_token) {
      return;
    }

    try {
      await retryNotification(async () => {
        await messaging.send({
          token: user.fcm_token,
          notification: {
            title,
            body,
          },
          data: data ? Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)])
          ) : undefined,
          android: {
            priority: 'high',
            notification: {
              channelId: 'afghan-bus-booking',
              priority: 'high',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        });
      }, { userId });

      logger.info('FCM notification sent', { userId });
    } catch (error) {
      logger.error('FCM notification failed', { userId, error: (error as Error).message });
      // Don't throw - FCM failure is non-critical
    }
  }

  /**
   * Send trip update notifications to all passengers
   */
  async sendTripUpdateNotifications(
    tripId: string,
    title: string,
    titleFa: string,
    titlePs: string
  ): Promise<void> {
    // Get all users with bookings for this trip
    const { data: bookings } = await supabase
      .from('bookings')
      .select('user_id')
      .eq('trip_id', tripId)
      .in('status', ['confirmed', 'paid']);

    if (!bookings || bookings.length === 0) return;

    const userIds = [...new Set(bookings.map((b) => b.user_id))];

    for (const userId of userIds) {
      try {
        await this.createNotification(
          userId,
          NotificationType.TRIP_UPDATE,
          title,
          titleFa,
          titlePs,
          { trip_id: tripId }
        );
      } catch (error) {
        logger.error('Failed to send trip update notification', {
          userId,
          tripId,
          error: (error as Error).message,
        });
      }
    }
  }
}

export const notificationService = new NotificationService();
