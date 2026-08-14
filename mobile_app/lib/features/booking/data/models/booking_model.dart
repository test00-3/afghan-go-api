enum BookingStatus { pending, confirmed, cancelled, completed }
enum PaymentStatus { pending, completed, failed, refunded }

class BookingModel {
  final String id;
  final String tripId;
  final String userId;
  final List<String> seatNumbers;
  final double totalAmount;
  final double depositAmount;
  final String paymentMethod;
  final BookingStatus bookingStatus;
  final PaymentStatus paymentStatus;
  final DateTime bookingDate;
  final DateTime tripDate;
  final String origin;
  final String destination;
  final String companyName;
  final String busType;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String? qrCode;

  BookingModel({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.seatNumbers,
    required this.totalAmount,
    required this.depositAmount,
    required this.paymentMethod,
    required this.bookingStatus,
    required this.paymentStatus,
    required this.bookingDate,
    required this.tripDate,
    required this.origin,
    required this.destination,
    required this.companyName,
    required this.busType,
    required this.departureTime,
    required this.arrivalTime,
    this.qrCode,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      userId: json['user_id'] ?? '',
      seatNumbers: List<String>.from(json['seat_numbers'] ?? []),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      depositAmount: (json['deposit_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      bookingStatus: BookingStatus.values.firstWhere(
        (e) => e.name == json['booking_status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      bookingDate: DateTime.parse(json['booking_date'] ?? DateTime.now().toIso8601String()),
      tripDate: DateTime.parse(json['trip_date'] ?? DateTime.now().toIso8601String()),
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      companyName: json['company_name'] ?? '',
      busType: json['bus_type'] ?? 'standard',
      departureTime: DateTime.parse(json['departure_time'] ?? DateTime.now().toIso8601String()),
      arrivalTime: DateTime.parse(json['arrival_time'] ?? DateTime.now().toIso8601String()),
      qrCode: json['qr_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'seat_numbers': seatNumbers,
      'total_amount': totalAmount,
      'deposit_amount': depositAmount,
      'payment_method': paymentMethod,
      'booking_status': bookingStatus.name,
      'payment_status': paymentStatus.name,
      'booking_date': bookingDate.toIso8601String(),
      'trip_date': tripDate.toIso8601String(),
      'origin': origin,
      'destination': destination,
      'company_name': companyName,
      'bus_type': busType,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'qr_code': qrCode,
    };
  }

  bool get isUpcoming => bookingStatus == BookingStatus.confirmed && tripDate.isAfter(DateTime.now());
  bool get isCompleted => bookingStatus == BookingStatus.completed;
  bool get isCancelled => bookingStatus == BookingStatus.cancelled;
  bool get isPending => paymentStatus == PaymentStatus.pending;
}
