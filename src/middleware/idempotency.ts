import { Request, Response, NextFunction } from 'express';
import { redis } from '../db/connection';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ middleware: 'idempotency' });

/**
 * Idempotency middleware
 * Prevents duplicate processing of the same request
 * Uses X-Idempotency-Key header
 */
export function idempotency(req: Request, res: Response, next: NextFunction): void {
  const idempotencyKey = req.headers['x-idempotency-key'] as string;

  if (!idempotencyKey) {
    // No idempotency key, proceed normally
    next();
    return;
  }

  // Create a unique key for this request
  const requestKey = `idempotency:${idempotencyKey}:${req.method}:${req.path}`;

  // Check if we've already processed this request
  const originalJson = res.json.bind(res);

  res.json = function (body: any) {
    // Store the response for this idempotency key
    redis.set(requestKey, JSON.stringify(body), 'EX', 86400).catch((err) => {
      logger.error('Failed to store idempotent response', { error: err.message });
    });

    return originalJson(body);
  };

  // Check for existing response
  redis.get(requestKey).then((existing) => {
    if (existing) {
      logger.info('Returning cached idempotent response', { idempotencyKey });
      try {
        const cachedBody = JSON.parse(existing);
        res.status(200).json(cachedBody);
      } catch {
        next();
      }
      return;
    }

    next();
  }).catch((err) => {
    logger.error('Idempotency check failed', { error: err.message });
    next();
  });
}

/**
 * Simple idempotency check for webhook endpoints
 * Returns true if this webhook has already been processed
 */
export async function isWebhookProcessed(
  provider: string,
  reference: string
): Promise<boolean> {
  const key = `webhook:${provider}:${reference}`;
  const exists = await redis.exists(key);
  return exists === 1;
}

/**
 * Mark webhook as processed
 */
export async function markWebhookProcessed(
  provider: string,
  reference: string
): Promise<void> {
  const key = `webhook:${provider}:${reference}`;
  await redis.set(key, '1', 'EX', 86400); // 24 hours
}
