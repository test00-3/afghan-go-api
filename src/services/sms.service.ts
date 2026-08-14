import { config } from '../config';
import { createContextLogger } from '../utils/logger';
import { retrySMS } from '../utils/retry';

const logger = createContextLogger({ service: 'sms' });

export interface SMSMessage {
  to: string;
  body: string;
}

/**
 * Send SMS using configured provider
 */
export async function sendSMS(to: string, body: string): Promise<void> {
  await retrySMS(async () => {
    switch (config.SMS_PROVIDER) {
      case 'twilio':
        await sendTwilioSMS(to, body);
        break;
      case 'aws_sns':
        await sendAWSSMS(to, body);
        break;
      case 'custom':
        await sendCustomSMS(to, body);
        break;
      default:
        logger.warn('SMS provider not configured, logging instead', { to, body });
        console.log(`[SMS] To: ${to}, Body: ${body}`);
    }
  }, { to });
}

/**
 * Send SMS via Twilio
 */
async function sendTwilioSMS(to: string, body: string): Promise<void> {
  const accountSid = config.TWILIO_ACCOUNT_SID;
  const authToken = config.TWILIO_AUTH_TOKEN;
  const fromNumber = config.TWILIO_PHONE_NUMBER;

  const url = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;

  const params = new URLSearchParams();
  params.append('To', to);
  params.append('From', fromNumber);
  params.append('Body', body);

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(`${accountSid}:${authToken}`).toString('base64')}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: params.toString(),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Twilio SMS failed: ${error.message}`);
  }

  logger.info('Twilio SMS sent', { to: to.slice(0, 6) + '***' });
}

/**
 * Send SMS via AWS SNS
 */
async function sendAWSSMS(to: string, body: string): Promise<void> {
  // AWS SNS implementation
  // This would use AWS SDK
  logger.info('AWS SNS SMS sent (placeholder)', { to: to.slice(0, 6) + '***' });
  console.log(`[AWS SNS SMS] To: ${to}, Body: ${body}`);
}

/**
 * Send SMS via custom provider
 */
async function sendCustomSMS(to: string, body: string): Promise<void> {
  // Custom SMS provider implementation
  logger.info('Custom SMS sent (placeholder)', { to: to.slice(0, 6) + '***' });
  console.log(`[Custom SMS] To: ${to}, Body: ${body}`);
}

/**
 * Send bulk SMS
 */
export async function sendBulkSMS(messages: SMSMessage[]): Promise<{ sent: number; failed: number }> {
  let sent = 0;
  let failed = 0;

  for (const message of messages) {
    try {
      await sendSMS(message.to, message.body);
      sent++;
    } catch (error) {
      failed++;
      logger.error('Bulk SMS failed', {
        to: message.to.slice(0, 6) + '***',
        error: (error as Error).message,
      });
    }
  }

  return { sent, failed };
}
