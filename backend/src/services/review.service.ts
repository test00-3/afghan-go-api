import { v4 as uuidv4 } from 'uuid';
import { supabase } from '../db/connection';
import {
  Review,
  ReviewWithUser,
  User,
  BookingStatus,
  NotFoundError,
  BookingError,
  ValidationError,
} from '../types';
import { createContextLogger } from '../utils/logger';

const logger = createContextLogger({ service: 'review' });

export class ReviewService {
  /**
   * Create a review for a trip
   */
  async createReview(
    userId: string,
    tripId: string,
    bookingId: string,
    rating: number,
    comment?: string
  ): Promise<Review> {
    // Validate booking exists and belongs to user
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('id, user_id, trip_id, status')
      .eq('id', bookingId)
      .eq('user_id', userId)
      .single();

    if (bookingError || !booking) {
      throw new NotFoundError('Booking');
    }

    if (booking.trip_id !== tripId) {
      throw new BookingError('Booking does not belong to this trip.');
    }

    if (booking.status !== BookingStatus.PAID && booking.status !== BookingStatus.CONFIRMED) {
      throw new BookingError('You can only review trips you have completed.');
    }

    // Check if user already reviewed this trip
    const { data: existingReview } = await supabase
      .from('reviews')
      .select('id')
      .eq('user_id', userId)
      .eq('trip_id', tripId)
      .single();

    if (existingReview) {
      throw new BookingError('You have already reviewed this trip.');
    }

    // Validate rating
    if (rating < 1 || rating > 5) {
      throw new ValidationError('Rating must be between 1 and 5.');
    }

    // Create review
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .insert({
        user_id: userId,
        trip_id: tripId,
        booking_id: bookingId,
        rating,
        comment: comment || null,
      })
      .select()
      .single();

    if (reviewError) {
      logger.error('Failed to create review', { error: reviewError.message });
      throw new Error('Failed to create review.');
    }

    // Update trip average rating
    await this.updateTripRating(tripId);

    logger.info('Review created', { reviewId: review.id, userId, tripId, rating });
    return review as Review;
  }

  /**
   * Get reviews for a trip
   */
  async getTripReviews(
    tripId: string,
    page: number = 1,
    limit: number = 20
  ): Promise<{ reviews: ReviewWithUser[]; averageRating: number; totalReviews: number }> {
    const offset = (page - 1) * limit;

    const { data: reviews, error } = await supabase
      .from('reviews')
      .select(
        `
        *,
        user:users(id, full_name, phone_number)
        `
      )
      .eq('trip_id', tripId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      throw new Error('Failed to fetch reviews.');
    }

    // Get average rating and total count
    const { data: stats } = await supabase
      .from('reviews')
      .select('rating')
      .eq('trip_id', tripId);

    const allReviews = stats || [];
    const totalReviews = allReviews.length;
    const averageRating =
      totalReviews > 0
        ? allReviews.reduce((sum, r) => sum + r.rating, 0) / totalReviews
        : 0;

    return {
      reviews: (reviews || []) as ReviewWithUser[],
      averageRating: Math.round(averageRating * 10) / 10,
      totalReviews,
    };
  }

  /**
   * Update trip average rating
   */
  private async updateTripRating(tripId: string): Promise<void> {
    const { data: reviews } = await supabase
      .from('reviews')
      .select('rating')
      .eq('trip_id', tripId);

    if (!reviews || reviews.length === 0) return;

    const avgRating = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;

    await supabase
      .from('trips')
      .update({ updated_at: new Date().toISOString() })
      .eq('id', tripId);
  }

  /**
   * Get user's reviews
   */
  async getUserReviews(userId: string): Promise<Review[]> {
    const { data, error } = await supabase
      .from('reviews')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error('Failed to fetch user reviews.');
    }

    return (data || []) as Review[];
  }

  /**
   * Delete a review
   */
  async deleteReview(userId: string, reviewId: string): Promise<void> {
    const { data: review, error: fetchError } = await supabase
      .from('reviews')
      .select('*')
      .eq('id', reviewId)
      .eq('user_id', userId)
      .single();

    if (fetchError || !review) {
      throw new NotFoundError('Review');
    }

    const { error } = await supabase
      .from('reviews')
      .delete()
      .eq('id', reviewId);

    if (error) {
      throw new Error('Failed to delete review.');
    }

    // Update trip rating
    await this.updateTripRating(review.trip_id);

    logger.info('Review deleted', { reviewId, userId });
  }
}

export const reviewService = new ReviewService();
