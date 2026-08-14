import { Request, Response } from 'express';
import { paymentService } from '../services/payment.service';
import { PaymentError } from '../types';
import { isWebhookProcessed, markWebhookProcessed } from '../middleware/idempotency';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ handler: 'payment' });

/**
 * POST /api/payments/hesabpay/webhook
 * HesabPay payment callback
 */
export async function hesabpayWebhook(req: Request, res: Response): Promise<void> {
  try {
    const payload = req.body;

    // Check if already processed
    const reference = payload.reference_id as string;
    if (reference && await isWebhookProcessed('hesabpay', reference)) {
      logger.info('HesabPay webhook already processed', { reference });
      res.status(200).json({ status: 'already_processed' });
      return;
    }

    const payment = await paymentService.verifyHesabPayWebhook(payload);

    // Mark as processed
    if (reference) {
      await markWebhookProcessed('hesabpay', reference);
    }

    logger.info('HesabPay webhook processed', {
      reference,
      status: payment.status,
      bookingId: payment.booking_id,
    });

    res.status(200).json({ status: 'ok' });
  } catch (error) {
    if (error instanceof PaymentError) {
      logger.error('HesabPay webhook failed', {
        error: error.message,
        payload: req.body,
      });
      res.status(400).json({
        status: 'error',
        message: error.message,
      });
    } else {
      logger.error('HesabPay webhook error', { error: (error as Error).message });
      res.status(500).json({
        status: 'error',
        message: 'Internal server error.',
      });
    }
  }
}

/**
 * POST /api/payments/momo/webhook
 * MoMo payment callback
 */
export async function momoWebhook(req: Request, res: Response): Promise<void> {
  try {
    const payload = req.body;

    // Check if already processed
    const reference = payload.externalId as string || payload.financialTransactionId as string;
    if (reference && await isWebhookProcessed('momo', reference)) {
      logger.info('MoMo webhook already processed', { reference });
      res.status(200).json({ status: 'already_processed' });
      return;
    }

    const payment = await paymentService.verifyMoMoWebhook(payload);

    // Mark as processed
    if (reference) {
      await markWebhookProcessed('momo', reference);
    }

    logger.info('MoMo webhook processed', {
      reference,
      status: payment.status,
      bookingId: payment.booking_id,
    });

    res.status(200).json({ status: 'ok' });
  } catch (error) {
    if (error instanceof PaymentError) {
      logger.error('MoMo webhook failed', {
        error: error.message,
        payload: req.body,
      });
      res.status(400).json({
        status: 'error',
        message: error.message,
      });
    } else {
      logger.error('MoMo webhook error', { error: (error as Error).message });
      res.status(500).json({
        status: 'error',
        message: 'Internal server error.',
      });
    }
  }
}

/**
 * GET /api/payments/:bookingId/status
 * Check payment status for a booking
 */
export async function getPaymentStatus(req: Request, res: Response): Promise<void> {
  try {
    const { bookingId } = req.params;

    const payments = await paymentService.getPaymentByBookingId(bookingId);

    const latestPayment = payments[0];

    res.status(200).json({
      success: true,
      data: {
        booking_id: bookingId,
        payments: payments.map((p) => ({
          id: p.id,
          provider: p.provider,
          amount: p.amount,
          currency: p.currency,
          status: p.status,
          created_at: p.created_at,
        })),
        latest_status: latestPayment?.status || 'no_payment',
      },
    });
  } catch (error) {
    logger.error('Get payment status failed', {
      bookingId: req.params.bookingId,
      error: (error as Error).message,
    });
    res.status(500).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get payment status.',
      },
    });
  }
}
