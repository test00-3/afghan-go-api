import { supabase } from '../db/connection';
import {
  Trip,
  TripWithDetails,
  TripSearchParams,
  PaginatedResponse,
  TripStatus,
  Bus,
  Company,
  TripError,
  NotFoundError,
  AFGHAN_CITIES,
  City,
} from '../types';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ service: 'trip' });

export class TripService {
  /**
   * Search trips with filters
   */
  async searchTrips(
    params: TripSearchParams
  ): Promise<PaginatedResponse<TripWithDetails>> {
    const {
      origin,
      destination,
      date,
      bus_type,
      min_price,
      max_price,
      page = 1,
      limit = 20,
    } = params;

    let query = supabase
      .from('trips')
      .select(
        `
        *,
        bus:buses(*),
        company:companies(*)
        `,
        { count: 'exact' }
      )
      .eq('status', TripStatus.SCHEDULED)
      .gt('available_seats', 0)
      .order('departure_time', { ascending: true });

    // Apply filters
    if (origin) {
      query = query.ilike('origin', `%${origin}%`);
    }
    if (destination) {
      query = query.ilike('destination', `%${destination}%`);
    }
    if (date) {
      const startOfDay = `${date}T00:00:00`;
      const endOfDay = `${date}T23:59:59`;
      query = query.gte('departure_time', startOfDay).lte('departure_time', endOfDay);
    }
    if (min_price) {
      query = query.gte('price', min_price);
    }
    if (max_price) {
      query = query.lte('price', max_price);
    }

    // Pagination
    const offset = (page - 1) * limit;
    query = query.range(offset, offset + limit - 1);

    const { data, error, count } = await query;

    if (error) {
      logger.error('Failed to search trips', { error: error.message });
      throw new TripError('Failed to search trips.');
    }

    // Filter by bus_type if specified (since it's on the joined table)
    let trips = (data || []) as TripWithDetails[];
    if (bus_type) {
      trips = trips.filter((trip) => trip.bus?.bus_type === bus_type);
    }

    const total = count || 0;

    return {
      data: trips,
      pagination: {
        page,
        limit,
        total,
        total_pages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get trip by ID with full details
   */
  async getTripById(tripId: string): Promise<TripWithDetails> {
    const { data, error } = await supabase
      .from('trips')
      .select(
        `
        *,
        bus:buses(*),
        company:companies(*)
        `
      )
      .eq('id', tripId)
      .single();

    if (error || !data) {
      throw new NotFoundError('Trip');
    }

    return data as TripWithDetails;
  }

  /**
   * Get seat map for a trip
   */
  async getSeatMap(tripId: string): Promise<{ trip: TripWithDetails; seats: Array<{ seat_number: string; row: number; column: number; status: string }> }> {
    const trip = await this.getTripById(tripId);

    const { data: seats, error } = await supabase
      .from('seats')
      .select('seat_number, row_number as row, column_number as column, status')
      .eq('trip_id', tripId)
      .order('row_number')
      .order('column_number');

    if (error) {
      throw new TripError('Failed to fetch seat map.');
    }

    return {
      trip,
      seats: seats || [],
    };
  }

  /**
   * Create a new trip (admin/driver)
   */
  async createTrip(tripData: {
    bus_id: string;
    company_id: string;
    origin: string;
    destination: string;
    departure_time: string;
    arrival_time: string;
    price: number;
  }): Promise<Trip> {
    // Validate cities
    const validOrigin = AFGHAN_CITIES.find(
      (c) => c.name.toLowerCase() === tripData.origin.toLowerCase()
    );
    const validDestination = AFGHAN_CITIES.find(
      (c) => c.name.toLowerCase() === tripData.destination.toLowerCase()
    );

    if (!validOrigin || !validDestination) {
      throw new TripError('Invalid origin or destination city.');
    }

    if (validOrigin.name === validDestination.name) {
      throw new TripError('Origin and destination cannot be the same.');
    }

    // Get bus details
    const { data: bus, error: busError } = await supabase
      .from('buses')
      .select('*')
      .eq('id', tripData.bus_id)
      .single();

    if (busError || !bus) {
      throw new NotFoundError('Bus');
    }

    // Create trip
    const { data: trip, error: tripError } = await supabase
      .from('trips')
      .insert({
        bus_id: tripData.bus_id,
        company_id: tripData.company_id,
        origin: validOrigin.name,
        destination: validDestination.name,
        departure_time: tripData.departure_time,
        arrival_time: tripData.arrival_time,
        price: tripData.price,
        status: TripStatus.SCHEDULED,
        available_seats: bus.total_seats,
      })
      .select()
      .single();

    if (tripError) {
      logger.error('Failed to create trip', { error: tripError.message });
      throw new TripError('Failed to create trip.');
    }

    // Create seats for the trip
    await this.createSeatsForTrip(trip.id, bus.total_seats);

    logger.info('Trip created', { tripId: trip.id, origin: validOrigin.name, destination: validDestination.name });
    return trip as Trip;
  }

  /**
   * Create seats for a trip based on bus capacity
   */
  private async createSeatsForTrip(tripId: string, totalSeats: number): Promise<void> {
    const seats = [];
    const seatsPerRow = 4; // 2 on each side of aisle
    const totalRows = Math.ceil(totalSeats / seatsPerRow);

    for (let row = 1; row <= totalRows; row++) {
      for (let col = 1; col <= seatsPerRow; col++) {
        const seatIndex = (row - 1) * seatsPerRow + col;
        if (seatIndex > totalSeats) break;

        const seatNumber = `${row}${String.fromCharCode(64 + col)}`; // e.g., 1A, 1B, 1C, 1D
        seats.push({
          trip_id: tripId,
          seat_number: seatNumber,
          row_number: row,
          column_number: col,
          status: 'available',
        });
      }
    }

    const { error } = await supabase.from('seats').insert(seats);

    if (error) {
      logger.error('Failed to create seats', { tripId, error: error.message });
      throw new TripError('Failed to create seats for trip.');
    }
  }

  /**
   * Update trip status
   */
  async updateTripStatus(tripId: string, status: TripStatus): Promise<Trip> {
    const { data, error } = await supabase
      .from('trips')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', tripId)
      .select()
      .single();

    if (error) {
      throw new TripError('Failed to update trip status.');
    }

    return data as Trip;
  }

  /**
   * Get popular routes
   */
  async getPopularRoutes(): Promise<Array<{ origin: string; destination: string; trip_count: number }>> {
    const { data, error } = await supabase
      .from('trips')
      .select('origin, destination')
      .eq('status', TripStatus.SCHEDULED)
      .gte('departure_time', new Date().toISOString());

    if (error) {
      return [];
    }

    // Count routes
    const routeCounts = new Map<string, { origin: string; destination: string; count: number }>();

    for (const trip of data || []) {
      const key = `${trip.origin}-${trip.destination}`;
      const existing = routeCounts.get(key);
      if (existing) {
        existing.count++;
      } else {
        routeCounts.set(key, {
          origin: trip.origin,
          destination: trip.destination,
          count: 1,
        });
      }
    }

    return Array.from(routeCounts.values())
      .sort((a, b) => b.count - a.count)
      .slice(0, 10)
      .map((r) => ({ origin: r.origin, destination: r.destination, trip_count: r.count }));
  }

  /**
   * Get list of cities
   */
  getCities(): City[] {
    return AFGHAN_CITIES;
  }
}

export const tripService = new TripService();
