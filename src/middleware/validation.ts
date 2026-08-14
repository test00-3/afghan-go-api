import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import { ValidationError } from '../types';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ middleware: 'validation' });

/**
 * Request validation middleware using Zod schemas
 */
export function validate(schema: ZodSchema, source: 'body' | 'query' | 'params' = 'body') {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const data = schema.parse(req[source]);
      req[source] = data;
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const formattedErrors = error.errors.map((err) => ({
          field: err.path.join('.'),
          message: err.message,
        }));

        logger.warn('Validation failed', {
          source,
          errors: formattedErrors,
          path: req.path,
        });

        res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Request validation failed',
            details: formattedErrors,
          },
        });
      } else {
        next(error);
      }
    }
  };
}

/**
 * Sanitize string inputs to prevent XSS
 */
export function sanitizeInput(input: string): string {
  return input
    .replace(/[<>]/g, '') // Remove angle brackets
    .trim();
}

/**
 * Validate and sanitize request body
 */
export function validateAndSanitize(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const data = schema.parse(req.body);

      // Sanitize string fields
      const sanitized = Object.fromEntries(
        Object.entries(data).map(([key, value]) => {
          if (typeof value === 'string') {
            return [key, sanitizeInput(value)];
          }
          return [key, value];
        })
      );

      req.body = sanitized;
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const formattedErrors = error.errors.map((err) => ({
          field: err.path.join('.'),
          message: err.message,
        }));

        res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Request validation failed',
            details: formattedErrors,
          },
        });
      } else {
        next(error);
      }
    }
  };
}
