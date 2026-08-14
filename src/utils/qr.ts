import QRCode from 'qrcode';

export interface TicketQRData {
  booking_ref: string;
  trip_id: string;
  seats: string[];
  passenger_phone: string;
  origin: string;
  destination: string;
  departure_time: string;
  company: string;
}

export async function generateTicketQR(data: TicketQRData): Promise<string> {
  const qrPayload = JSON.stringify({
    ref: data.booking_ref,
    trip: data.trip_id,
    seats: data.seats.join(','),
    phone: data.passenger_phone,
    route: `${data.origin}-${data.destination}`,
    depart: data.departure_time,
    company: data.company,
  });

  try {
    const qrDataUrl = await QRCode.toDataURL(qrPayload, {
      errorCorrectionLevel: 'M',
      margin: 2,
      width: 300,
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
    });
    return qrDataUrl;
  } catch (error) {
    throw new Error(`Failed to generate QR code: ${(error as Error).message}`);
  }
}

export async function generateTicketQRBuffer(data: TicketQRData): Promise<Buffer> {
  const qrPayload = JSON.stringify({
    ref: data.booking_ref,
    trip: data.trip_id,
    seats: data.seats.join(','),
    phone: data.passenger_phone,
    route: `${data.origin}-${data.destination}`,
    depart: data.departure_time,
    company: data.company,
  });

  try {
    const buffer = await QRCode.toBuffer(qrPayload, {
      errorCorrectionLevel: 'M',
      margin: 2,
      width: 300,
    });
    return buffer;
  } catch (error) {
    throw new Error(`Failed to generate QR buffer: ${(error as Error).message}`);
  }
}

export function decodeTicketQR(qrString: string): TicketQRData | null {
  try {
    const data = JSON.parse(qrString);
    if (!data.ref || !data.trip || !data.seats) {
      return null;
    }
    return {
      booking_ref: data.ref,
      trip_id: data.trip,
      seats: typeof data.seats === 'string' ? data.seats.split(',') : data.seats,
      passenger_phone: data.phone || '',
      origin: data.route?.split('-')[0] || '',
      destination: data.route?.split('-')[1] || '',
      departure_time: data.depart || '',
      company: data.company || '',
    };
  } catch {
    return null;
  }
}
