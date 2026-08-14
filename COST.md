# Afghan Go - Cost Analysis

Detailed breakdown of infrastructure costs for the Afghan Go Bus Ticket Booking System.

---

## Summary

| Component        | Monthly Cost (MVP) | Monthly Cost (Scale) |
|------------------|---------------------|----------------------|
| Database         | $0                  | $25                  |
| Backend Hosting  | $0                  | $20                  |
| Push Notifications | $0                | $0                   |
| Caching          | $0                  | $10                  |
| Payments         | Transaction fees    | Transaction fees     |
| SMS              | ~$5                 | ~$50                 |
| Domain           | ~$1                 | ~$1                  |
| **Total**        | **~$6/month**       | **~$106/month**      |

---

## Free Tier Details

### Supabase (Database + Auth + Storage + Realtime)

| Feature             | Free Tier Limit                    |
|---------------------|-------------------------------------|
| Database            | 500 MB                             |
| File Storage        | 1 GB                               |
| Monthly Active Users| 50,000                             |
| Auth Users          | Unlimited                          |
| Edge Functions      | 500K invocations/month             |
| Realtime            | 200 concurrent connections         |
| Bandwidth           | 5 GB/month                         |

**What fits in 500 MB:**
- ~500,000 booking records
- ~50,000 user profiles
- ~100,000 trip records
- ~500,000 payment records
- All city/route/reference data

**At MVP scale (1,000 bookings/day):**
- 30,000 bookings/month = ~30 MB
- Well within free tier

---

### Railway (Backend Hosting)

| Feature            | Free Tier Limit                    |
|--------------------|-------------------------------------|
| Credits            | $5/month                           |
| Build minutes      | 500/month                          |
| Deployment         | Unlimited                          |
| Bandwidth          | 100 GB/month                       |

**What $5/month gets you:**
- ~500 hours of basic Node.js runtime
- Sufficient for MVP with 1,000 daily requests
- Auto-sleep after inactivity (can be disabled on paid plans)

**Alternative: Render (Free Tier)**
| Feature            | Free Tier Limit                    |
|--------------------|-------------------------------------|
| Web Services       | 1 instance                         |
| Instance Size      | 512 MB RAM, 0.5 CPU               |
| Bandwidth          | 100 GB/month                       |
| Build minutes      | 500/month                          |
| Auto-sleep         | After 15 min inactivity            |

---

### Firebase (Push Notifications)

| Feature                | Free Tier Limit              |
|------------------------|-------------------------------|
| Notifications/day      | 50,000                       |
| Topics                 | 2,000                        |
| Targeting              | Unlimited                    |
| Analytics              | Unlimited                    |

**Capacity:**
- 50K notifications/day = 1.5M/month
- Sufficient for 50K+ active users
- Each booking generates ~3 notifications (confirmation, reminder, arrival)
- 1,000 bookings/day = 3,000 notifications/day = well under limit

---

### Redis (Upstash - Serverless Redis)

| Feature                | Free Tier Limit              |
|------------------------|-------------------------------|
| Commands               | 10,000/day                   |
| Storage                | 256 MB                       |
| Connections            | Concurrent                   |

**What fits:**
- Seat locks: ~1,000 active locks = ~50 KB
- Session cache: ~5,000 sessions = ~100 KB
- Rate limiting counters: ~100 KB
- Trip search cache: ~100 KB

**Note:** 10K commands/day is tight for production. Upgrade to paid plan ($10/month) for 500K commands/day if needed.

**Alternative: Supabase Realtime (built-in)**
- Use Supabase Realtime for seat updates instead of separate Redis
- Included in Supabase free tier

---

### Payment Gateways

#### HesabPay

| Feature            | Cost                              |
|--------------------|-----------------------------------|
| Setup Fee          | Free                              |
| Monthly Fee        | Free                              |
| Transaction Fee    | 2-3% per transaction              |
| Payout             | Next business day                 |

**Example:** 1,000 bookings/month × 320 AFN avg deposit = 320,000 AFN volume
- At 2.5% fee = 8,000 AFN (~$90) in fees
- Platform absorbs or passes to customer

#### MoMo (My Money)

| Feature            | Cost                              |
|--------------------|-----------------------------------|
| Setup Fee          | Free                              |
| Monthly Fee        | Free                              |
| Transaction Fee    | 1.5-2.5% per transaction          |
| Payout             | Same day                          |

#### PayPal

| Feature            | Cost                              |
|--------------------|-----------------------------------|
| Setup Fee          | Free                              |
| Monthly Fee        | Free                              |
| Transaction Fee    | 3.49% + fixed fee                |
| International      | Additional 1.5% conversion fee    |

**Recommendation:** Use HesabPay and MoMo as primary gateways for Afghan users. PayPal for international/diaspora users.

---

### SMS Gateway (AF SMS Gateway / Twilio)

#### Local Afghan SMS Gateway

| Feature            | Cost                              |
|--------------------|-----------------------------------|
| Per SMS            | ~0.5-1 AFN (~$0.006-0.012)       |
| Setup              | Varies by provider                |

**Monthly estimate:**
- 1,000 bookings × 2 SMS each = 2,000 SMS
- 2,000 × $0.01 = $20/month

#### Twilio (Alternative)

| Feature            | Cost                              |
|--------------------|-----------------------------------|
| Per SMS (Afghanistan) | $0.05 per message             |
| Monthly Fee        | Free                              |

**Monthly estimate:**
- 2,000 SMS × $0.05 = $100/month (expensive for Afghanistan)

**Recommendation:** Use local Afghan SMS provider for 5-10x cost savings.

---

### Domain Name

| Feature            | Cost                              |
|--------------------|-----------------------------------|
| .com domain        | ~$12/year (~$1/month)            |
| .af domain         | ~$50/year (~$4/month)            |
| SSL Certificate    | Free (Let's Encrypt)              |

**Recommendation:** Register both afghango.com and afghango.af for ~$5/month total.

---

## Cost Scenarios

### Scenario 1: MVP Launch (0-1,000 users/month)

| Component        | Cost/month |
|------------------|------------|
| Supabase         | $0         |
| Railway          | $0         |
| Firebase         | $0         |
| Upstash Redis    | $0         |
| SMS (local)      | $5         |
| Domain           | $1         |
| **Total**        | **$6**     |

### Scenario 2: Growth (1,000-10,000 users/month)

| Component        | Cost/month |
|------------------|------------|
| Supabase         | $0 (still within free tier) |
| Railway          | $20 (paid plan) |
| Firebase         | $0         |
| Upstash Redis    | $10 (paid plan for more commands) |
| SMS (local)      | $25        |
| Domain           | $1         |
| **Total**        | **$56**    |

### Scenario 3: Scale (10,000-50,000 users/month)

| Component        | Cost/month |
|------------------|------------|
| Supabase Pro     | $25        |
| Railway Pro      | $20        |
| Firebase         | $0         |
| Upstash Redis    | $10        |
| SMS (local)      | $50        |
| Domain           | $1         |
| Monitoring       | $0-20      |
| **Total**        | **$106-126** |

### Scenario 4: Production (50,000+ users/month)

| Component        | Cost/month |
|------------------|------------|
| Supabase Team    | $75        |
| Railway Team     | $20        |
| Firebase         | $25 (Blaze plan) |
| Upstash Redis    | $10        |
| SMS (local)      | $100       |
| Domain           | $1         |
| CDN (Cloudflare) | $0 (free)  |
| Monitoring       | $20        |
| **Total**        | **$251**   |

---

## Revenue Model

### Per-Booking Revenue

| Source              | Amount           |
|---------------------|------------------|
| Booking fee         | 50-100 AFN       |
| Payment processing  | 2-3% of payment  |
| VIP upgrade upsell  | 200-400 AFN      |
| Insurance add-on    | 50-100 AFN       |

### Break-even Analysis

**At $6/month MVP cost:**
- Need ~10 bookings/month at 100 AFN fee = 1,000 AFN (~$12) to break even
- Easily achievable in Afghan market

**At $106/month growth cost:**
- Need ~1,060 bookings/month at 100 AFN fee to break even
- ~35 bookings/day average

---

## Optimization Tips

1. **Use Supabase Edge Functions** instead of a separate backend for simple endpoints
2. **Cache aggressively** with Redis to reduce database queries
3. **Use Supabase Realtime** instead of WebSocket server for seat updates
4. **Batch SMS notifications** to reduce per-message costs
5. **Use Firebase topics** for bulk notifications instead of targeting individual devices
6. **Implement pagination** to reduce payload sizes and database load
7. **Use CDN** (Cloudflare free tier) for static assets and API caching

---

## Cost Monitoring

### Set up billing alerts:

**Supabase:**
- Dashboard → Settings → Usage → Set alerts at 80% and 95% of limits

**Railway:**
- Dashboard → Settings → Usage → Set monthly budget alerts

**Firebase:**
- Console → Usage and billing → Set budget alerts

**Upstash:**
- Dashboard → Usage → Set command count alerts

---

## Total Cost Summary

| Phase        | Users    | Bookings/Month | Cost/Month |
|--------------|----------|----------------|------------|
| MVP          | 0-1,000  | 0-3,000        | $6         |
| Growth       | 1,000-10K| 3,000-30,000   | $56        |
| Scale        | 10K-50K  | 30K-150,000    | $106       |
| Production   | 50K+     | 150,000+       | $251+      |

**Key insight:** Afghan Go can launch and operate completely free for the first 1,000 users. Even at scale, costs remain highly competitive due to free tier utilization and local payment/SMS providers.

---

## Comparison with Alternatives

| Approach              | Monthly Cost | Limitations                    |
|-----------------------|--------------|--------------------------------|
| Afghan Go (this)      | $0-6         | None significant for MVP       |
| Custom full-stack     | $200+        | Need DevOps expertise          |
| No-code (Bubble)      | $32+         | Limited customization          |
| SaaS booking system   | $100+        | Not tailored for Afghanistan   |
| Outsource development | $5,000+      | One-time + maintenance         |

**Afghan Go provides the best value for Afghan market deployment.**
