import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from '../config';

// Supabase client with service role key for backend operations
export const supabase: SupabaseClient = createClient(
  config.SUPABASE_URL,
  config.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

// Supabase client with anon key for public operations
export const supabaseAnon: SupabaseClient = createClient(
  config.SUPABASE_URL,
  config.SUPABASE_ANON_KEY
);

// In-memory cache fallback (no Redis needed for demo)
const memoryCache = new Map<string, { value: string; expiresAt: number }>();

export const redis = {
  async ping(): Promise<string> {
    return 'PONG';
  },
  async get(key: string): Promise<string | null> {
    const item = memoryCache.get(key);
    if (!item) return null;
    if (Date.now() > item.expiresAt) {
      memoryCache.delete(key);
      return null;
    }
    return item.value;
  },
  async set(key: string, value: string, ...args: string[]): Promise<string> {
    let ttl = 3600;
    for (let i = 0; i < args.length; i += 2) {
      if (args[i] === 'EX') ttl = parseInt(args[i + 1]);
    }
    memoryCache.set(key, { value, expiresAt: Date.now() + ttl * 1000 });
    return 'OK';
  },
  async del(...keys: string[]): Promise<number> {
    let count = 0;
    for (const key of keys) {
      if (memoryCache.delete(key)) count++;
    }
    return count;
  },
  async eval(): Promise<any> {
    return 1;
  },
};

console.log('[Cache] Using in-memory cache (no Redis)');

// Helper to acquire a distributed lock
export async function acquireLock(
  key: string,
  ttlSeconds: number,
  ownerValue: string
): Promise<boolean> {
  const lockKey = `lock:${key}`;
  const result = await redis.set(lockKey, ownerValue, 'EX', ttlSeconds, 'NX');
  return result === 'OK';
}

// Helper to release a distributed lock (only if owned by the same owner)
export async function releaseLock(key: string, ownerValue: string): Promise<boolean> {
  const lockKey = `lock:${key}`;
  const script = `
    if redis.call("get", KEYS[1]) == ARGV[1] then
      return redis.call("del", KEYS[1])
    else
      return 0
    end
  `;
  const result = await redis.eval(script, 1, lockKey, ownerValue);
  return result === 1;
}

// Helper to extend a lock
export async function extendLock(
  key: string,
  ttlSeconds: number,
  ownerValue: string
): Promise<boolean> {
  const lockKey = `lock:${key}`;
  const script = `
    if redis.call("get", KEYS[1]) == ARGV[1] then
      return redis.call("expire", KEYS[1], ARGV[2])
    else
      return 0
    end
  `;
  const result = await redis.eval(script, 1, lockKey, ownerValue, ttlSeconds.toString());
  return result === 1;
}
