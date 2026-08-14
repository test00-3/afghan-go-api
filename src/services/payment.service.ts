import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import { supabase } from '../db/connection';
import {
  Payment,
  PaymentProvider,
  PaymentStatus,
  PaymentError,
} from '../types';
import { config } from '../config';
import { createContextLogger } from '../utils/logger';
import { retryPayment } from '../utils/retry';
import { bookingService } from './booking.service';

const logger = createContextLogger({ service: 'payment' });

export class PaymentService {
  // ============ HESABPAY ============

  async createHesabPayPayment(
    bookingId: string,
    amount: number,
    description: string
  ): Promise<{ paymentUrl: string; reference: string }> {
    const reference = `HP${uuidv4().slice(0, 8).toUpperCase()}`;

    // Create payment record
    await this.createPaymentRecord(bookingId, PaymentProvider.HESABPAY, amount, reference);

    // Call HesabPay API
    try {
      const result = await retryPayment(async () => {
        const response = await fetch(`${config.HESABPAY_API_URL}/v1/payment/create`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${config.HESABPAY_SECRET_KEY}`,
          },
          body: JSON.stringify({
            merchant_id: config.HESABPAY_MERCHANT_ID,
            amount: amount,
            currency: 'AFN',
            description,
            reference_id: reference,
            callback_url: config.HESABPAY_CALLBACK_URL,
            return_url: `${config.FRONTEND_URL}/booking/${bookingId}`,
          }),
        });

        if (!response.ok) {
          const error = await response.json();
          throw new Error(error.message || 'HesabPay API error');
        }

        return response.json();
      });

      logger.info('HesabPay payment created', { bookingId, reference });
      return {
        paymentUrl: result.payment_url || result.redirect_url,
        reference,
      };
    } catch (error) {
      logger.error('HesabPay payment creation failed', { error: (error as Error).message });
      throw new PaymentError('Failed to create HesabPay payment. Please try again.');
    }
  }

  async verifyHesabPayWebhook(payload: Record<string, unknown>): Promise<Payment> {
    // Verify webhook signature
    const signature = payload.signature as string;
    const expectedSignature = this.generateHesabPaySignature(payload);

    if (signature !== expectedSignature) {
      throw new PaymentError('Invalid webhook signature.');
    }

    const reference = payload.reference_id as string;
    const status = payload.status === 'successful' ? PaymentStatus.COMPLETED : PaymentStatus.FAILED;

    return this.processWebhookPayment(reference, status, payload);
  }

  private generateHesabPaySignature(payload: Record<string, unknown>): string {
    const sortedKeys = Object.keys(payload)
      .filter((k) => k !== 'signature')
      .sort();
    const sortedValues = sortedKeys.map((k) => `${k}=${payload[k]}`).join('&');
    return crypto
      .createHmac('sha256', config.HESABPAY_SECRET_KEY)
      .update(sortedValues)
      .digest('hex');
  }

  // ============ MOMO ============

  async createMoMoPayment(
    bookingId: string,
    amount: number,
    description: string
  ): Promise<{ paymentUrl: string; reference: string }> {
    const reference = `MM${uuidv4().slice(0, 8).toUpperCase()}`;

    await this.createPaymentRecord(bookingId, PaymentProvider.MOMO, amount, reference);

    try {
      const result = await retryPayment(async () => {
        const response = await fetch(`${config.MOMO_API_URL}/collection/v1_0/requesttopay`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.getMoMoAccessToken()}`,
            'X-Reference-Id': reference,
            'X-Target-Environment': config.PAYPAL_MODE === 'sandbox' ? 'sandbox' : 'production',
          },
          body: JSON.stringify({
            amount: amount.toString(),
            currency: 'AFN',
            externalId: bookingId,
            payer: {
              partyIdType: 'MSISDN',
              partyId: '',
            },
            payerMessage: description,
            payeeNote: `Booking payment for ${bookingId}`,
          }),
        });

        if (!response.ok) {
          const error = await response.json();
          throw new Error(error.message || 'MoMo API error');
        }

        return { reference };
      });

      logger.info('MoMo payment initiated', { bookingId, reference });
      return {
        paymentUrl: `${config.MOMO_API_URL}/collection/v1_0/pay/${reference}`,
        reference,
      };
    } catch (error) {
      logger.error('MoMo payment creation failed', { error: (error as Error).message });
      throw new PaymentError('Failed to initiate MoMo payment. Please try again.');
    }
  }

  async verifyMoMoWebhook(payload: Record<string, unknown>): Promise<Payment> {
    const reference = payload.externalId as string || payload.financialTransactionId as string;
    const status = payload.status === 'SUCCESSFUL' ? PaymentStatus.COMPLETED : PaymentStatus.FAILED;

    return this.processWebhookPayment(reference, status, payload);
  }

  private getMoMoAccessToken(): string {
    const credentials = `${config.MOMO_API_KEY}:${config.MOMO_MERCHANT_ID}`;
    return Buffer.from(credentials).toString('base64');
  }

  // ============ PAYPAL ============

  async createPayPalOrder(
    bookingId: string,
    amount: number,
    description: string
  ): Promise<{ orderId: string; approvalUrl: string }> {
    const reference = `PP${uuidv4().slice(0, 8).toUpperCase()}`;

    await this.createPaymentRecord(bookingId, PaymentProvider.PAYPAL, amount, reference);

    try {
      const result = await retryPayment(async () => {
        const accessToken = await this.getPayPalAccessToken();

        const response = await fetch(
          `${config.PAYPAL_MODE === 'sandbox' ? 'https://api-m.sandbox.paypal.com' : 'https://api-m.paypal.com'}/v2/checkout/orders`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify({
              intent: 'CAPTURE',
              purchase_units: [
                {
                  reference_id: reference,
                  description,
                  amount: {
                    currency_code: 'USD',
                    value: (amount / 85).toFixed(2), // AFN to USD approx
                  },
                },
              ],
              application_context: {
                return_url: `${config.FRONTEND_URL}/booking/${bookingId}/payment-success`,
                cancel_url: `${config.FRONTEND_URL}/booking/${bookingId}/payment-cancel`,
              },
            }),
          }
        );

        if (!response.ok) {
          const error = await response.json();
          throw new Error(error.message || 'PayPal API error');
        }

        return response.json();
      });

      const approvalUrl = result.links?.find((l: any) => l.rel === 'approve')?.href;

      logger.info('PayPal order created', { bookingId, reference, orderId: result.id });
      return {
        orderId: result.id,
        approvalUrl: approvalUrl || '',
      };
    } catch (error) {
      logger.error('PayPal order creation failed', { error: (error as Error).message });
      throw new PaymentError('Failed to create PayPal order. Please try again.');
    }
  }

  private async getPayPalAccessToken(): Promise<string> {
    const auth = Buffer.from(
      `${config.PAYPAL_CLIENT_ID}:${config.PAYPAL_CLIENT_SECRET}`
    ).toString('base64');

    const response = await fetch(
      `${config.PAYPAL_MODE === 'sandbox' ? 'https://api-m.sandbox.paypal.com' : 'https://api-m.paypal.com'}/v1/oauth2/token`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      }
    );

    const data = await response.json();
    return data.access_token;
  }

  // ============ COMMON ============

  async createPaymentRecord(
    bookingId: string,
    provider: PaymentProvider,
    amount: number,
    reference: string
  ): Promise<Payment> {
    const { data, error } = await supabase
      .from('payments')
      .insert({
        booking_id: bookingId,
        provider,
        provider_reference: reference,
        amount,
        currency: 'AFN',
        status: PaymentStatus.PENDING,
      })
      .select()
      .single();

    if (error) {
      throw new PaymentError('Failed to create payment record.');
    }

    return data as Payment;
  }

  async processWebhookPayment(
    reference: string,
    status: PaymentStatus,
    webhookPayload: Record<string, unknown>
  ): Promise<Payment> {
    // Find payment by reference
    const { data: payment, error: fetchError } = await supabase
      .from('payments')
      .select('*')
      .eq('provider_reference', reference)
      .single();

    if (fetchError || !payment) {
      throw new PaymentError('Payment not found.');
    }

    // Update payment status
    const { error: updateError } = await supabase
      .from('payments')
      .update({
        status,
        webhook_payload: webhookPayload,
        updated_at: new Date().toISOString(),
      })
      .eq('id', payment.id);

    if (updateError) {
      throw new PaymentError('Failed to update payment status.');
    }

    // If payment completed, confirm booking
    if (status === PaymentStatus.COMPLETED) {
      try {
        await bookingService.confirmBooking(payment.booking_id, reference);
        logger.info('Payment completed, booking confirmed', { paymentId: payment.id, bookingId: payment.booking_id });
      } catch (error) {
        logger.error('Failed to confirm booking after payment', {
          paymentId: payment.id,
          bookingId: payment.booking_id,
          error: (error as Error).message,
        });
      }
    }

    logger.info('Webhook processed', { reference, status, provider: payment.provider });
    return { ...payment, status } as Payment;
  }

  async getPaymentByBookingId(bookingId: string): Promise<Payment[]> {
    const { data, error } = await supabase
      .from('payments')
      .select('*')
      .eq('booking_id', bookingId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new PaymentError('Failed to fetch payments.');
    }

    return (data || []) as Payment[];
  }
}

export const paymentService = new PaymentService();
