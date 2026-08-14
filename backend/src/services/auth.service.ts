import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { supabase } from '../db/connection';
import { redis } from '../db/connection';
import { config } from '../config';
import {
  User,
  UserRole,
  Language,
  AuthError,
  OTP_TTL_SECONDS,
} from '../types';
import { createContextLogger } from '../utils/logger';
import { OTP_MESSAGES, getMessage } from '../utils/messages';
import { sendSMS } from './sms.service';

const logger = createContextLogger({ service: 'auth' });

export interface TokenPayload {
  user_id: string;
  phone_number: string;
  role: UserRole;
  iat: number;
  exp: number;
}

export class AuthService {
  /**
   * Generate a 6-digit OTP
   */
  private generateOTP(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  /**
   * Send OTP to phone number
   */
  async sendOTP(phoneNumber: string, language: Language = Language.DARI): Promise<{ message: string }> {
    const otp = this.generateOTP();
    const otpKey = `otp:${phoneNumber}`;

    // Store OTP in Redis with TTL
    await redis.set(otpKey, otp, 'EX', OTP_TTL_SECONDS);

    // Send SMS
    const messageTemplate = OTP_MESSAGES;
    const { body } = getMessage(messageTemplate, language, { otp });

    try {
      await sendSMS(phoneNumber, body);
      logger.info('OTP sent successfully', { phoneNumber: phoneNumber.slice(0, 6) + '***' });
    } catch (error) {
      logger.error('Failed to send OTP SMS', { error: (error as Error).message });
      // Don't throw - OTP is still stored in Redis for testing
      if (config.NODE_ENV === 'production') {
        throw new AuthError('Failed to send OTP. Please try again.');
      }
    }

    return { message: 'OTP sent successfully' };
  }

  /**
   * Verify OTP and return JWT
   */
  async verifyOTP(
    phoneNumber: string,
    otp: string
  ): Promise<{ token: string; user: User }> {
    const otpKey = `otp:${phoneNumber}`;
    const storedOTP = await redis.get(otpKey);

    if (!storedOTP) {
      throw new AuthError('OTP has expired. Please request a new one.');
    }

    if (storedOTP !== otp) {
      throw new AuthError('Invalid OTP. Please try again.');
    }

    // Delete OTP after successful verification
    await redis.del(otpKey);

    // Find or create user
    let user = await this.findUserByPhone(phoneNumber);

    if (!user) {
      user = await this.createUser(phoneNumber);
    }

    // Generate JWT
    const token = this.generateToken(user);

    logger.info('User authenticated', { userId: user.id });
    return { token, user };
  }

  /**
   * Find user by phone number
   */
  async findUserByPhone(phoneNumber: string): Promise<User | null> {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('phone_number', phoneNumber)
      .single();

    if (error || !data) {
      return null;
    }

    return data as User;
  }

  /**
   * Create a new user
   */
  async createUser(phoneNumber: string, language: Language = Language.DARI): Promise<User> {
    const { data, error } = await supabase
      .from('users')
      .insert({
        phone_number: phoneNumber,
        role: UserRole.PASSENGER,
        preferred_language: language,
      })
      .select()
      .single();

    if (error) {
      logger.error('Failed to create user', { error: error.message });
      throw new AuthError('Failed to create user account.');
    }

    return data as User;
  }

  /**
   * Get user by ID
   */
  async getUserById(userId: string): Promise<User> {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (error || !data) {
      throw new AuthError('User not found.');
    }

    return data as User;
  }

  /**
   * Update user profile
   */
  async updateUser(
    userId: string,
    updates: Partial<Pick<User, 'full_name' | 'preferred_language' | 'fcm_token'>>
  ): Promise<User> {
    const { data, error } = await supabase
      .from('users')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      throw new AuthError('Failed to update user profile.');
    }

    return data as User;
  }

  /**
   * Update FCM token for push notifications
   */
  async updateFCMToken(userId: string, fcmToken: string): Promise<void> {
    const { error } = await supabase
      .from('users')
      .update({ fcm_token: fcmToken, updated_at: new Date().toISOString() })
      .eq('id', userId);

    if (error) {
      logger.error('Failed to update FCM token', { userId, error: error.message });
    }
  }

  /**
   * Generate JWT token
   */
  private generateToken(user: User): string {
    const payload: TokenPayload = {
      user_id: user.id,
      phone_number: user.phone_number,
      role: user.role,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60, // 30 days
    };

    return jwt.sign(payload as object, config.JWT_SECRET);
  }

  /**
   * Verify JWT token
   */
  verifyToken(token: string): TokenPayload {
    try {
      const decoded = jwt.verify(token, config.JWT_SECRET) as TokenPayload;
      return decoded;
    } catch (error) {
      throw new AuthError('Invalid or expired token.');
    }
  }
}

export const authService = new AuthService();
