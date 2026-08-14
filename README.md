# Afghan Go - افغان ګو

## Bus Ticket Booking System | سیستم رزرو بلیط بس | د بس ټکت رزرو سیسټم

---

# English

## Overview

Afghan Go is a complete bus ticket booking system designed for inter-provincial travel across Afghanistan. It enables passengers to search routes between 14 major Afghan cities, select seats in real-time, pay via local payment gateways, and receive QR code tickets — all from their mobile device.

## Architecture

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│                     │     │                     │     │                     │
│   Flutter Mobile    │◄───►│   Node.js API       │◄───►│   PostgreSQL        │
│   App (iOS/Android) │     │   (TypeScript)      │     │   (Supabase)        │
│                     │     │                     │     │                     │
└─────────┬───────────┘     └─────────┬───────────┘     └─────────────────────┘
          │                           │                           │
          │                           │                           │
          ▼                           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   Firebase          │     │   Redis             │     │   Storage           │
│   (Push + SMS)      │     │   (Caching/Locks)   │     │   (Supabase S3)     │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
```

## Tech Stack

| Component        | Technology                    |
|------------------|-------------------------------|
| Mobile App       | Flutter 3.x, Dart             |
| Backend API      | Node.js 20+, TypeScript       |
| Database         | PostgreSQL 15+ (Supabase)     |
| Auth             | Supabase Auth + JWT           |
| Realtime         | Supabase Realtime + Redis     |
| Push Notifs      | Firebase Cloud Messaging      |
| SMS              | AF SMS Gateway / Twilio       |
| Payments         | HesabPay, MoMo, PayPal        |
| Hosting          | Railway / Render / VPS        |
| CI/CD            | GitHub Actions                |

## Features

- Search trips between 14 Afghan cities (Kabul, Herat, Mazar-i-Sharif, Kandahar, Jalalabad, Kunduz, Bamyan, Lashkar Gah, Gardez, Taloqan, Sheberghan, Pul-e-Khumri, Mehtarlam, Panjshir)
- Real-time seat selection with visual 40-seat bus layout
- 3 payment gateways: HesabPay, MoMo (My Money), PayPal
- 20% deposit booking — pay remaining 80% at terminal
- Full trilingual support: Dari (فارسی), Pashto (پښتو), English
- VIP bus services with premium pricing
- Push notifications + SMS confirmations
- QR code ticket generation and scanning
- Real-time seat locking to prevent double bookings
- Admin dashboard for bus operators
- Trip scheduling and management
- Revenue analytics and reporting

## Prerequisites

- Node.js 20+ and npm/yarn
- Flutter 3.x SDK
- PostgreSQL 15+ (or Supabase account)
- Supabase project (free tier works)
- Firebase project (free tier works)
- Redis instance (free tier works)
- HesabPay merchant account (or sandbox)
- MoMo merchant account (or sandbox)

## Step-by-Step Deployment Guide

### 1. Database Setup (Supabase)

```bash
# 1. Create a free Supabase project at https://supabase.com
# 2. Note your project URL and service role key
# 3. Run the schema

# Option A: Using the deploy script
./scripts/deploy-db.sh <SUPABASE_URL> <SERVICE_ROLE_KEY>

# Option B: Manual via Supabase SQL Editor
# Copy contents of schema/supabase_schema.sql into SQL Editor and run
```

### 2. Backend Deployment

```bash
# Option A: Railway (recommended)
# 1. Push code to GitHub
# 2. Create Railway account at https://railway.app
# 3. New Project → Deploy from GitHub
# 4. Add environment variables (see ENV section below)
# 5. Railway auto-deploys on push

# Option B: Render
# 1. Create Render account at https://render.com
# 2. New Web Service → Connect GitHub
# 3. Set build command: npm install && npm run build
# 4. Set start command: npm start
# 5. Add environment variables

# Option C: VPS (DigitalOcean/Hetzner)
# 1. SSH into server
# 2. Run setup script
./scripts/setup.sh
# 3. Run deploy script
./scripts/deploy-backend.sh
```

### 3. Flutter App Build

```bash
# 1. Navigate to Flutter project
cd afghan-go-app

# 2. Get dependencies
flutter pub get

# 3. Configure environment
cp .env.example .env
# Edit .env with your API URL

# 4. Build APK (Android)
flutter build apk --release

# 5. Build IPA (iOS) — requires Mac
flutter build ipa --release

# 6. Build Web (optional)
flutter build web --release
```

## Environment Variables

### Backend (.env)

```bash
# Server
PORT=3000
NODE_ENV=production
API_VERSION=v1

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Database
DATABASE_URL=postgresql://postgres:password@db.your-project.supabase.co:5432/postgres

# Redis
REDIS_URL=redis://default:password@redis-host:6379

# JWT
JWT_SECRET=your-64-char-random-secret
JWT_EXPIRES_IN=7d

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# Payments
HESABPAY_API_KEY=your-hesabpay-key
HESABPAY_MERCHANT_ID=your-merchant-id
MOMO_API_KEY=your-momo-key
MOMO_MERCHANT_ID=your-momo-merchant-id
PAYPAL_CLIENT_ID=your-paypal-client-id
PAYPAL_CLIENT_SECRET=your-paypal-secret

# SMS
SMS_API_KEY=your-sms-key
SMS_SENDER_ID=AFGOGO

# App
FRONTEND_URL=https://afghango.app
SUPPORT_EMAIL=support@afghango.app
```

## API Documentation Summary

| Method | Endpoint                          | Description              |
|--------|-----------------------------------|--------------------------|
| POST   | /api/v1/auth/register            | Register new user        |
| POST   | /api/v1/auth/login               | Login                    |
| POST   | /api/v1/auth/refresh             | Refresh token            |
| GET    | /api/v1/trips/search             | Search available trips   |
| GET    | /api/v1/trips/:id                | Get trip details         |
| GET    | /api/v1/trips/:id/seats          | Get seat availability    |
| POST   | /api/v1/bookings                 | Create booking           |
| GET    | /api/v1/bookings/:id             | Get booking details      |
| POST   | /api/v1/bookings/:id/pay         | Process payment          |
| GET    | /api/v1/bookings/:id/ticket      | Get QR ticket            |
| POST   | /api/v1/payments/hesabpay        | HesabPay callback        |
| POST   | /api/v1/payments/momo            | MoMo callback            |
| GET    | /api/v1/cities                   | List all cities          |
| GET    | /api/v1/buses                    | List bus operators       |
| GET    | /api/v1/admin/dashboard          | Admin analytics          |

Full API docs: See [API.md](./API.md)

## Cost Estimate

| Service         | Free Tier                           | Monthly Cost |
|-----------------|-------------------------------------|--------------|
| Supabase        | 500MB DB, 1GB storage, 50K MAU     | $0           |
| Railway         | $5 credit/month                     | $0           |
| Firebase        | 50K push notifs/day                 | $0           |
| Redis (Upstash) | 10K commands/day                    | $0           |
| HesabPay        | Transaction fees only               | $0           |
| **Total MVP**   |                                     | **$0**       |

See detailed breakdown: [COST.md](./COST.md)

## Security Features

- JWT-based authentication with refresh tokens
- Row Level Security (RLS) on all Supabase tables
- Rate limiting (100 req/min per user)
- Input validation and sanitization
- HTTPS enforced on all endpoints
- Payment webhook signature verification
- Seat locking with Redis TTL (5 min timeout)
- PCI DSS compliance via third-party payment processors
- No card data stored on servers

---

# فارسی (دری)

## نمای کلی

افغان ګو یک سیستم کامل رزرو بلیط بس برای سفرهای بین ولایتی در افغانستان طراحی شده است. این سیستم به مسافران امکان می‌دهد تا مسیرها بین ۱۴ شهر بزرگ افغانستان را جستجو کنند، صندلی‌ها را به صورت بلادرنگ انتخاب کنند، از طریق درگاه‌های پرداخت محلی پرداخت کنند و بلیط QR کد دریافت کنند — همه از طریق دستگاه موبایل خود.

## معماری

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│                     │     │                     │     │                     │
│   اپلیکیشن موبایل   │◄───►│   API سرور          │◄───►│   پایگاه داده       │
│   Flutter (اندروید/آیفون)│  │   Node.js           │     │   PostgreSQL        │
│                     │     │   (TypeScript)      │     │   (Supabase)        │
└─────────┬───────────┘     └─────────┬───────────┘     └─────────────────────┘
          │                           │                           │
          ▼                           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   Firebase          │     │   Redis             │     │   فضای ذخیره‌سازی   │
│   (اعلانات + SMS)    │     │   (کش و قفل‌ها)     │     │   (Supabase S3)     │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
```

## فن آوری‌ها

| بخش              | فن آوری                          |
|------------------|-----------------------------------|
| اپلیکیشن موبایل  | Flutter 3.x, Dart                 |
| سرور API         | Node.js 20+, TypeScript           |
| پایگاه داده      | PostgreSQL 15+ (Supabase)         |
| احراز هویت       | Supabase Auth + JWT               |
| بلادرنگ          | Supabase Realtime + Redis         |
| اعلانات          | Firebase Cloud Messaging          |
| پیامک            | دروازه پیامک افغانستان / Twilio   |
| پرداخت‌ها         | حساب‌پی, مومی, پی‌پل              |
| میزبانی          | Railway / Render / VPS            |

## امکانات

- جستجوی سفر بین ۱۴ شهر افغانستان (کابل، هرات، مزارشریف، کندهار، جلال‌آباد، کندز، بامیان، لشکرگاه، گردیز، تالقان، شبرغان، پل‌خمری، مهترلام، پنجشیر)
- انتخاب بلادرنگ صندلی با نقشه بصری اتوبوس ۴۰ صندلی
- ۳ درگاه پرداخت: حساب‌پی، مومی، پی‌پل
- رزرو با ۲۰٪ پیش‌پرداخت — پرداخت ۸۰٪ باقی‌مانده در تerminal
- پشتیبانی کامل سه زبانه: دری، پښتو، انگلیسی
- خدمات اتوبوس ویژه با قیمت بالاتر
- اعلانات فشاری + تأییدیه پیامکی
- تولید و اسکن بلیط QR کد
- قفل صندلی بلادرنگ برای جلوگیری از رزرو دوبل
- داشبورد مدیریت برای شرکت‌های اتوبوسرانی
- برنامه‌ریزی و مدیریت سفرها
- تحلیل درآمد و گزارش‌دهی

## پیش‌نیازها

- Node.js 20+ و npm/yarn
- Flutter 3.x SDK
- PostgreSQL 15+ (یا حساب Supabase)
- پروژه Supabase (سطح رایگان کافی است)
- پروژه Firebase (سطح رایگان کافی است)
- نمونه Redis (سطح رایگان کافی است)
- حساب بازرگانی حساب‌پی (یا sandbox)
- حساب بازرگانی مومی (یا sandbox)

## راهنمای استقرار گام به گام

### ۱. راه‌اندازی پایگاه داده (Supabase)

```bash
# ۱. یک پروژه رایگان Supabase در https://supabase.com ایجاد کنید
# ۲. آدرس پروژه و کلید نقش سرویس خود را یادداشت کنید
# ۳. طرح را اجرا کنید

# گزینه الف: استفاده از اسکریپت استقرار
./scripts/deploy-db.sh <SUPABASE_URL> <SERVICE_ROLE_KEY>

# گزینه ب: دستی از طریق ویرایشگر SQL Supabase
# محتویات schema/supabase_schema.sql را در ویرایشگر SQL کپی و اجرا کنید
```

### ۲. استقرار سرور

```bash
# گزینه الف: Railway (توصیه شده)
# ۱. کد را در GitHub قرار دهید
# ۲. حساب Railway در https://railway.app ایجاد کنید
# ۳. پروژه جدید → استقرار از GitHub
# ۴. متغیرهای محیطی را اضافه کنید (به بخش ENV مراجعه کنید)
# ۵. Railway به صورت خودکار استقرار می‌دهد

# گزینه ب: Render
# ۱. حساب Render در https://render.com ایجاد کنید
# ۲. سرویس وب جدید → اتصال GitHub
# ۳. دستور ساخت: npm install && npm run build
# ۴. دستور شروع: npm start
# ۵. متغیرهای محیطی را اضافه کنید
```

### ۳. ساخت اپلیکیشن Flutter

```bash
# ۱. به پروژه Flutter بروید
cd afghan-go-app

# ۲. وابستگی‌ها را دریافت کنید
flutter pub get

# ۳. محیط را پیکربندی کنید
cp .env.example .env
# فایل .env را با آدرس API خود ویرایش کنید

# ۴. APK بسازید (اندروید)
flutter build apk --release

# ۵. IPA بسازید (آیفون) — به Mac نیاز دارد
flutter build ipa --release
```

## متغیرهای محیطی

### سرور (.env)

```bash
# سرور
PORT=3000
NODE_ENV=production
API_VERSION=v1

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# پایگاه داده
DATABASE_URL=postgresql://postgres:password@db.your-project.supabase.co:5432/postgres

# Redis
REDIS_URL=redis://default:password@redis-host:6379

# JWT
JWT_SECRET=your-64-char-random-secret
JWT_EXPIRES_IN=7d

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# پرداخت‌ها
HESABPAY_API_KEY=your-hesabpay-key
HESABPAY_MERCHANT_ID=your-merchant-id
MOMO_API_KEY=your-momo-key
MOMO_MERCHANT_ID=your-momo-merchant-id
PAYPAL_CLIENT_ID=your-paypal-client-id
PAYPAL_CLIENT_SECRET=your-paypal-secret

# پیامک
SMS_API_KEY=your-sms-key
SMS_SENDER_ID=AFGOGO

# اپلیکیشن
FRONTEND_URL=https://afghango.app
SUPPORT_EMAIL=support@afghango.app
```

## خلاصه مستندات API

| متد   | مسیر                               | توضیح                    |
|-------|-------------------------------------|--------------------------|
| POST  | /api/v1/auth/register              | ثبت‌نام کاربر جدید       |
| POST  | /api/v1/auth/login                 | ورود                     |
| POST  | /api/v1/auth/refresh               | تازه‌سازی توکن           |
| GET   | /api/v1/trips/search               | جستجوی سفرهای موجود     |
| GET   | /api/v1/trips/:id                  | جزئیات سفر               |
| GET   | /api/v1/trips/:id/seats            | وضعیت صندلی‌ها           |
| POST  | /api/v1/bookings                   | ایجاد رزرو               |
| GET   | /api/v1/bookings/:id               | جزئیات رزرو              |
| POST  | /api/v1/bookings/:id/pay           | پردازش پرداخت            |
| GET   | /api/v1/bookings/:id/ticket        | دریافت بلیط QR           |
| GET   | /api/v1/cities                     | فهرست شهرها              |

مستندات کامل API: [API.md](./API.md)

## تخمین هزینه

| خدمت             | سطح رایگان                          | هزینه ماهانه |
|-----------------|-------------------------------------|--------------|
| Supabase        | ۵۰۰MB پایگاه داده، ۱GB فضا       | $0           |
| Railway         | $5 اعتبار/ماه                       | $0           |
| Firebase        | ۵۰K اعلان/روز                      | $0           |
| Redis (Upstash) | ۱۰K دستور/روز                      | $0           |
| حساب‌پی          | فقط کارمزد تراکنش                   | $0           |
| **کل MVP**      |                                     | **$0**       |

جزئیات: [COST.md](./COST.md)

## ویژگی‌های امنیتی

- احراز هویت مبتنی بر JWT با توکن‌های تازه‌سازی
- امنیت سطح ردیف (RLS) روی تمام جداول Supabase
- محدودیت نرخ (۱۰۰ درخواست/دقیقه به ازای هر کاربر)
- اعتبارسنجی و پاکسازی ورودی‌ها
- HTTPS اجباری روی تمام مسیرها
- تأیید امضای webhook پرداخت
- قفل صندلی با TTL Redis (مهلت ۵ دقیقه)
- انطباق PCI DSS از طریق پردازندگان پرداخت شخص ثالث
- هیچ داده کارتی روی سرورها ذخیره نمی‌شود

---

# پښتو

## تفصیل

افغان ګو د افغانستان کې د بین ولایتي سفرونو لپې یو بشپړ بس ټکت رزرو سیسټم دی. دا مسافرو ته وړتیا ورکوي چې د ۱۴ لویو شارونو ترڅاپه مسیرونه لټون کړئ، په واقعي وخت کې ځایونه غوره کړئ، د محلي پرداخت دروازې له لارې پرداخت وکړئ او QR کوډ بلیط تر لاسه راکړئ — ټول د خپل موبایل اسله له لارې.

## آرشیټکچر

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│                     │     │                     │     │                     │
│   موبایل اپلیکیشن   │◄───►│   API سرور          │◄───►│   ډیټابیس           │
│   Flutter (اندروید/آیفون)│  │   Node.js           │     │   PostgreSQL        │
│                     │     │   (TypeScript)      │     │   (Supabase)        │
└─────────┬───────────┘     └─────────┬───────────┘     └─────────────────────┘
          │                           │                           │
          ▼                           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   Firebase          │     │   Redis             │     │   ذخیره‌سازی        │
│   (خبرتیاوې + SMS)  │     │   (کیش او قفلونه)   │     │   (Supabase S3)     │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
```

## ټکنالوجي

| برخه             | ټکنالوجي                           |
|------------------|-------------------------------------|
| موبایل اپلیکیشن  | Flutter 3.x, Dart                   |
| API سرور         | Node.js 20+, TypeScript             |
| ډیټابیس          | PostgreSQL 15+ (Supabase)           |
| تصدیق            | Supabase Auth + JWT                 |
| ریلټایم          | Supabase Realtime + Redis           |
| خبرتیاوې         | Firebase Cloud Messaging            |
| پیغامکونه        | د افغانستان پیغامک دروازه / Twilio  |
| پرداختونه        | حساب‌پی، مومی، پی‌پل                 |
| میزبانی          | Railway / Render / VPS              |

## ځانګړتیاوې

- د ۱۴ شارونو ترڅاپه (کابل، هرات، مزارشریف، کندهار، جلال‌آباد، کندز، بامیان، لشکرگاه، گردیز، تالقان، شبرغان، پل‌خمری، مهترلام، پنجشیر) سفرونو لټون
- په واقعي وخت کې د ۴۰ ځایونو بس نقشې سره ځای غوره کول
- ۳ پرداخت دروازې: حساب‌پی، مومی، پی‌پل
- د ۲۰٪ مخکینی پرداخت سره رزرو — په terminal کې ۸۰٪ ویش پرداخت
- دری، پښتو، انګلیسي دری ژبه ملاتړ
- VIP بس خدمتونه
- خبرتیاوې + د پیغامک تایید
- QR کوډ بلیټونه
- د چټک رزرو阻止 لپې په واقعي وخت کې ځای قفل کول
- د بس ډلیلونو لپې ادمین ډشبورډ
- سفرونو میرات او اداره
- عاید تحلیل

## مخکینی څیړنې

- Node.js 20+ او npm/yarn
- Flutter 3.x SDK
- PostgreSQL 15+ (یا Supabase حساب)
- Supabase پروژه (ورکړه پلور راته کې کافی دی)
- Firebase پروژه (ورکړه پلور راته کې کافی دی)
- Redis (ورکړه پلور راته کې کافی دی)
- حساب‌پی تاجري حساب (یا sandbox)
- مومی تاجري حساب (یا sandbox)

## د استقرار ګام پر ګام لارښود

### ۱. ډیټابیس راموز (Supabase)

```bash
# ۱. په https://supabase.com کې یو ورکړه Supabase پروژه جوړ کړئ
# ۲. خپل پروژه آدرس او سرویس رول کلید یاد کړئ
# ۳. سیمې راړاندیز کړئ

# انتخاب اول: د استقرار اسکریپت کارول
./scripts/deploy-db.sh <SUPABASE_URL> <SERVICE_ROLE_KEY>

# انتخاب دویم: له Supabase SQL ایډیټر له لارې
# schema/supabase_schema.sql مطالب کپی کړئ او اجرا کړئ
```

### ۲. سرور استقرار

```bash
# انتخاب اول: Railway (سپارښتیا شوې)
# ۱. کوډ GitHub ته پورته کړئ
# ۲. د Railway حساب په https://railway.app ایجاد کړئ
# ۳. نوې پروژه → له GitHub استقرار
# ۴. د محيطي متغيرونه اضافه کړئ (د ENV برخه وګورئ)
# ۵. Railway په اوتوماتیک طرز استقرار کوي

# انتخاب دویم: Render
# ۱. Render حساب په https://render.com ایجاد کړئ
# ۲. نوې ویب سرویس → GitHub وصل کړئ
# ۳. جوړولو حکم: npm install && npm run build
# ۴. پیل حکم: npm start
# ۵. د محيطي متغيرونه اضافه کړئ
```

### ۳. Flutter اپلیکیشن جوړول

```bash
# ۱. د Flutter پروژه ته وګورئ
cd afghan-go-app

# ۲. تابعیتونه تر لاسه راکړئ
flutter pub get

# ۳. محيط ټکنیکال کړئ
cp .env.example .env
# .env د خپل API آدرس سره ویرایش کړئ

# ۴. APK جوړ کړئ (اندروید)
flutter build apk --release

# ۵. IPA جوړ کړئ (آیفون) — Mac ته اړین دی
flutter build ipa --release
```

## د محيطي متغيرونه

### سرور (.env)

```bash
# سرور
PORT=3000
NODE_ENV=production
API_VERSION=v1

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# ډیټابیس
DATABASE_URL=postgresql://postgres:password@db.your-project.supabase.co:5432/postgres

# Redis
REDIS_URL=redis://default:password@redis-host:6379

# JWT
JWT_SECRET=your-64-char-random-secret
JWT_EXPIRES_IN=7d

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# پرداختونه
HESABPAY_API_KEY=your-hesabpay-key
HESABPAY_MERCHANT_ID=your-merchant-id
MOMO_API_KEY=your-momo-key
MOMO_MERCHANT_ID=your-momo-merchant-id
PAYPAL_CLIENT_ID=your-paypal-client-id
PAYPAL_CLIENT_SECRET=your-paypal-secret

# پیغامکونه
SMS_API_KEY=your-sms-key
SMS_SENDER_ID=AFGOGO

# اپلیکیشن
FRONTEND_URL=https://afghango.app
SUPPORT_EMAIL=support@afghango.app
```

## د API مستندات خلاصه

| میتود | پاته                               | تفصیل                    |
|-------|-------------------------------------|--------------------------|
| POST  | /api/v1/auth/register              | نوی کاربر ثبت‌نام         |
| POST  | /api/v1/auth/login                 | ننوتل                    |
| POST  | /api/v1/auth/refresh               | ټوکن تازه کول             |
| GET   | /api/v1/trips/search               | د شته سفرونو لټون        |
| GET   | /api/v1/trips/:id                  | د سفر تفصیل              |
| GET   | /api/v1/trips/:id/seats            | د ځایونو حالت            |
| POST  | /api/v1/bookings                   | رزرو جوړ کول             |
| GET   | /api/v1/bookings/:id               | د رزرو تفصیل             |
| POST  | /api/v1/bookings/:id/pay           | پرداخت پروسیس کول        |
| GET   | /api/v1/bookings/:id/ticket        | QR بلیط تر لاسه راکړئ    |
| GET   | /api/v1/cities                     | د شارونو لیست            |

د API بشپړ مستندات: [API.md](./API.md)

## د لګونو شمیړ

| خدمت             | ورکړه پلور                           | میاشتې لګونه |
|-----------------|---------------------------------------|--------------|
| Supabase        | ۵۰۰MB ډیټابیس، ۱GB ځای             | $0           |
| Railway         | $5 اعتبار/میاشتې                      | $0           |
| Firebase        | ۵۰K خبرتیاوې/ورځ                     | $0           |
| Redis (Upstash) | ۱۰K حکمونه/ورځ                       | $0           |
| حساب‌پی          | یوازې د لیږد لګونه                   | $0           |
| **ټول MVP**     |                                       | **$0**       |

د تفصیل لپې: [COST.md](./COST.md)

## د امنیت ځانګړتیاوې

- JWT مبتنی تصدیق د تازه ټوکنونو سره
- د ټولو Supabase جدولونو پر د SLR (Row Level Security)
- نرخ حد (کارن پر میاشتې ۱۰۰ غوښتنې)
- د ورودیونو غوره کول او سافټ کول
- ټولو endpointونو پر HTTPS اجباري
- د پرداخت webhook م帅 تایید
- Redis TTL سره ځای قله کول (۵ دقیقې مهلت)
- د دریم حزب پرداخت پروسیسرانو له لارې PCI DSS د اړیکه
- هیڅ کارت ډیټا په سرورونو کې نه خوندیږي
