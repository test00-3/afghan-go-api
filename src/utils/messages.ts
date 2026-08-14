import { Language } from '../types';

interface MessageTemplate {
  subject?: string;
  subject_fa?: string;
  subject_ps?: string;
  body: string;
  body_fa: string;
  body_ps: string;
}

// OTP Messages
export const OTP_MESSAGES: MessageTemplate = {
  subject: 'Verification Code',
  subject_fa: 'کد تأیید',
  subject_ps: 'تأیید کوډ',
  body: 'Dear passenger, your verification code: {otp}. Valid for 5 minutes.',
  body_fa: 'مسافر گرامی، کد تأیید شما: {otp}. برای ۵ دقیقه معتبر است.',
  body_ps: 'ګرامی مسافر، ستاسو تأیید کوډ: {otp}. د ۵ دقیقو لپاره جوړ دی.',
};

// Booking Confirmed
export const BOOKING_CONFIRMED_MESSAGES: MessageTemplate = {
  subject: 'Booking Confirmed',
  subject_fa: 'رزرو تأیید شد',
  subject_ps: 'زیارت تأیید شوې',
  body: 'Dear passenger, your ticket for {origin}-{destination} with {company}, seat(s) {seats} is confirmed. Pay remaining {balance} AFN at the terminal. Booking ref: {bookingRef}',
  body_fa: 'مسافر گرامی، تیکت شما برای مسیر {origin}-{destination} در شرکت {company}، چوکی شماره {seats} تایید شد. مابقی مبلغ {balance} افغانی را در ترمینال پرداخت کنید. کد رزرو: {bookingRef}',
  body_ps: 'ګرامی مسافر، ستاسو بلیط د {origin} څخه {destination} لارې لپاره په {company} شرکت کې د {seats} سیټونو لپاره تأیید شوې. پاتې {balance} افغانۍ ترمینال کې وپریږدل شۍ. زیارت کوډ: {bookingRef}',
};

// Payment Received
export const PAYMENT_RECEIVED_MESSAGES: MessageTemplate = {
  subject: 'Payment Received',
  subject_fa: 'پرداخت دریافت شد',
  subject_ps: 'تادیه ترلاسه شوې',
  body: 'Dear passenger, your payment of {amount} AFN for booking {bookingRef} has been received successfully.',
  body_fa: 'مسافر گرامی، پرداخت {amount} افغانی برای رزرو {bookingRef} با موفقیت دریافت شد.',
  body_ps: 'ګرامی مسافر، ستاسو د {amount} افغانیو تادیه د {bookingRef} زیارت لپاره په بریالیتوب سره ترلاسه شوې.',
};

// Trip Update
export const TRIP_UPDATE_MESSAGES: MessageTemplate = {
  subject: 'Trip Update',
  subject_fa: 'بروزرسانی سفر',
  subject_ps: 'سفر تازه‌سازی',
  body: 'Dear passenger, your trip {origin}-{destination} has been updated. New departure time: {departureTime}. Please check your booking details.',
  body_fa: 'مسافر گرامی، سفر {origin}-{destination} شما بروزرسانی شده است. زمان جدید حرکت: {departureTime}. لطفاً جزئیات رزرو خود را بررسی کنید.',
  body_ps: 'ګرامی مسافر، ستاسو د {origin} څخه {destination} سفر تازه شوی. نوی د حرکت وخت: {departureTime}. مهرباني وکړئ ستاسو د زیارت تفصیلات وګورئ.',
};

// Trip Reminder
export const TRIP_REMINDER_MESSAGES: MessageTemplate = {
  subject: 'Trip Reminder',
  subject_fa: 'یادآوری سفر',
  subject_ps: 'د سفر یادونه',
  body: 'Dear passenger, reminder: Your trip {origin}-{destination} departs in {hours} hours. Please arrive at the terminal 30 minutes before departure.',
  body_fa: 'مسافر گرامی، یادآوری: سفر {origin}-{destination} شما در {hours} ساعت دیگر حرکت می‌کند. لطفاً ۳۰ دقیقه قبل از حرکت در ترمینال حاضر شوید.',
  body_ps: 'ګرامی مسافر، یادونه: ستاسو د {origin} څخه {destination} سفر د {hours} ساعتو ورو حرکت کوي. مهرباني وکړئ د حرکت څخه ۳۰ دقیقه مخکې ترمINAL کې حاضر شئ.',
};

// Booking Cancelled
export const BOOKING_CANCELLED_MESSAGES: MessageTemplate = {
  subject: 'Booking Cancelled',
  subject_fa: 'رزرو لغو شد',
  subject_ps: 'زیارت لغوه شوې',
  body: 'Dear passenger, your booking {bookingRef} for {origin}-{destination} has been cancelled. If you paid a deposit, refund will be processed within 3-5 business days.',
  body_fa: 'مسافر گرامی، رزرو {bookingRef} شما برای مسیر {origin}-{destination} لغو شد. اگر ودیعه پرداخت کرده باشید، ظرف ۳ تا ۵ روز کاری بازپرداخت خواهد شد.',
  body_ps: 'ګرامی مسافر، ستاسو د {origin} څخه {destination} زیارت {bookingRef} لغوه شوې. که تاسو شیان ورکړل، غواړ د ۳-۵ کارنیالونو پر وخت بیرته ورکړل کیږي.',
};

// Payment Failed
export const PAYMENT_FAILED_MESSAGES: MessageTemplate = {
  subject: 'Payment Failed',
  subject_fa: 'پرداخت ناموفق',
  subject_ps: 'تادیه ناکامه شوې',
  body: 'Dear passenger, your payment for booking {bookingRef} has failed. Please try again or use a different payment method.',
  body_fa: 'مسافر گرامی، پرداخت شما برای رزرو {bookingRef} ناموفق بود. لطفاً دوباره تلاش کنید یا روش پرداخت دیگری استفاده کنید.',
  body_ps: 'ګرامی مسافر، ستاسو د {bookingRef} زیارت لپاره تادیه ناکامه شوې. مهرباني وکړئ بیرته هڅه وکړئ یا بل تادیه طریقه وکاروئ.',
};

// Seat Lock Expiring
export const SEAT_LOCK_EXPIRING_MESSAGES: MessageTemplate = {
  subject: 'Seat Selection Expiring',
  subject_fa: 'انتخاب چوکی در حال انقضا',
  subject_ps: 'د سیټو غوره‌کول پوره کیږي',
  body: 'Dear passenger, your seat selection for {origin}-{destination} will expire in {minutes} minutes. Please complete your booking.',
  body_fa: 'مسافر گرامی، انتخاب چوکی شما برای مسیر {origin}-{destination} در {minutes} دقیقه منقضی می‌شود. لطفاً رزرو خود را تکمیل کنید.',
  body_ps: 'ګرامی مسافر، ستاسو د {origin} څخه {destination} سیټو غوره‌کول د {minutes} دقیقو ورو پوره کیږي. مهرباني وکړئ ستاسو زیارت بشپړ کړئ.',
};

export function getMessage(
  template: MessageTemplate,
  language: Language,
  variables: Record<string, string | number>
): { subject: string; body: string } {
  let subject = '';
  let body = '';

  switch (language) {
    case Language.DARI:
      subject = template.subject_fa || template.subject || '';
      body = template.body_fa;
      break;
    case Language.PASHTO:
      subject = template.subject_ps || template.subject || '';
      body = template.body_ps;
      break;
    case Language.ENGLISH:
    default:
      subject = template.subject || '';
      body = template.body;
      break;
  }

  // Replace variables
  for (const [key, value] of Object.entries(variables)) {
    const placeholder = `{${key}}`;
    body = body.replace(new RegExp(placeholder.replace(/[{}]/g, '\\$&'), 'g'), String(value));
    subject = subject.replace(new RegExp(placeholder.replace(/[{}]/g, '\\$&'), 'g'), String(value));
  }

  return { subject, body };
}
