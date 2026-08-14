import { Request, Response } from 'express';
import { authService } from '../services/auth.service';
import { OTPSendSchema, OTPVerifySchema, AuthError } from '../types';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ handler: 'auth' });

/**
 * POST /api/auth/otp/send
 * Send OTP to phone number
 */
export async function sendOTP(req: Request, res: Response): Promise<void> {
  try {
    const { phone_number, language } = OTPSendSchema.parse(req.body);

    const result = await authService.sendOTP(phone_number, language);

    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    if (error instanceof Error && 'statusCode' in error) {
      const appError = error as any;
      res.status(appError.statusCode).json({
        success: false,
        error: {
          code: appError.code,
          message: appError.message,
        },
      });
    } else {
      logger.error('Send OTP failed', { error: (error as Error).message });
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to send OTP.',
        },
      });
    }
  }
}

/**
 * POST /api/auth/otp/verify
 * Verify OTP and return JWT
 */
export async function verifyOTP(req: Request, res: Response): Promise<void> {
  try {
    const { phone_number, otp } = OTPVerifySchema.parse(req.body);

    const result = await authService.verifyOTP(phone_number, otp);

    res.status(200).json({
      success: true,
      data: {
        token: result.token,
        user: {
          id: result.user.id,
          phone_number: result.user.phone_number,
          full_name: result.user.full_name,
          role: result.user.role,
          preferred_language: result.user.preferred_language,
        },
      },
    });
  } catch (error) {
    if (error instanceof AuthError) {
      res.status(error.statusCode).json({
        success: false,
        error: {
          code: error.code,
          message: error.message,
        },
      });
    } else {
      logger.error('Verify OTP failed', { error: (error as Error).message });
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Failed to verify OTP.',
        },
      });
    }
  }
}

/**
 * GET /api/auth/me
 * Get current user profile
 */
export async function getMe(req: Request, res: Response): Promise<void> {
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

    const user = await authService.getUserById(req.user.user_id);

    res.status(200).json({
      success: true,
      data: {
        id: user.id,
        phone_number: user.phone_number,
        full_name: user.full_name,
        role: user.role,
        preferred_language: user.preferred_language,
        created_at: user.created_at,
      },
    });
  } catch (error) {
    logger.error('Get me failed', { error: (error as Error).message });
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get user profile.',
      },
    });
  }
}
