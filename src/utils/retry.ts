import { logger } from './logger';

interface RetryOptions {
  maxRetries: number;
  baseDelay: number;
  maxDelay: number;
  backoffFactor: number;
  retryableErrors?: string[];
}

const defaultOptions: RetryOptions = {
  maxRetries: 3,
  baseDelay: 1000,
  maxDelay: 10000,
  backoffFactor: 2,
};

export async function withRetry<T>(
  fn: () => Promise<T>,
  options: Partial<RetryOptions> = {},
  context: Record<string, unknown> = {}
): Promise<T> {
  const opts = { ...defaultOptions, ...options };
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= opts.maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;

      if (attempt === opts.maxRetries) {
        break;
      }

      // Check if error is retryable
      if (opts.retryableErrors && opts.retryableErrors.length > 0) {
        const errorName = lastError.name || '';
        const errorMessage = lastError.message || '';
        const isRetryable = opts.retryableErrors.some(
          (e) => errorName.includes(e) || errorMessage.includes(e)
        );
        if (!isRetryable) {
          throw lastError;
        }
      }

      const delay = Math.min(
        opts.baseDelay * Math.pow(opts.backoffFactor, attempt),
        opts.maxDelay
      );

      logger.warn('Retrying operation', {
        attempt: attempt + 1,
        maxRetries: opts.maxRetries,
        delay,
        error: lastError.message,
        ...context,
      });

      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  throw lastError;
}

export async function retryPayment<T>(
  fn: () => Promise<T>,
  context: Record<string, unknown> = {}
): Promise<T> {
  return withRetry(
    fn,
    {
      maxRetries: 3,
      baseDelay: 2000,
      maxDelay: 15000,
      backoffFactor: 2,
      retryableErrors: ['ECONNRESET', 'ETIMEDOUT', 'ECONNREFUSED', '502', '503', '504'],
    },
    { ...context, operation: 'payment' }
  );
}

export async function retrySMS<T>(
  fn: () => Promise<T>,
  context: Record<string, unknown> = {}
): Promise<T> {
  return withRetry(
    fn,
    {
      maxRetries: 2,
      baseDelay: 1000,
      maxDelay: 5000,
      backoffFactor: 2,
    },
    { ...context, operation: 'sms' }
  );
}

export async function retryNotification<T>(
  fn: () => Promise<T>,
  context: Record<string, unknown> = {}
): Promise<T> {
  return withRetry(
    fn,
    {
      maxRetries: 2,
      baseDelay: 500,
      maxDelay: 3000,
      backoffFactor: 2,
    },
    { ...context, operation: 'notification' }
  );
}
