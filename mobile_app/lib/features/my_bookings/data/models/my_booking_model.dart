class MyBookingModel {
  final String id;
  final String tripId;
  final String origin;
  final String destination;
  final DateTime tripDate;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String companyName;
  final String busType;
  final List<String> seatNumbers;
  final double totalAmount;
  final double paidAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String bookingStatus;
  final DateTime bookingDate;
  final String? qrCode;

  MyBookingModel({
    required this.id,
    required this.tripId,
    required this.origin,
    required this.destination,
    required this.tripDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.companyName,
    required this.busType,
    required this.seatNumbers,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.bookingDate,
    this.qrCode,
  });

  factory MyBookingModel.fromJson(Map<String, dynamic> json) {
    return MyBookingModel(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      tripDate: DateTime.parse(json['trip_date'] ?? DateTime.now().toIso8601String()),
      departureTime: DateTime.parse(json['departure_time'] ?? DateTime.now().toIso8601String()),
      arrivalTime: DateTime.parse(json['arrival_time'] ?? DateTime.now().toIso8601String()),
      companyName: json['company_name'] ?? '',
      busType: json['bus_type'] ?? 'standard',
      seatNumbers: List<String>.from(json['seat_numbers'] ?? []),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? 'pending',
      bookingStatus: json['booking_status'] ?? 'pending',
      bookingDate: DateTime.parse(json['booking_date'] ?? DateTime.now().toIso8601String()),
      qrCode: json['qr_code'],
    );
  }

  bool get isUpcoming => bookingStatus == 'confirmed' && tripDate.isAfter(DateTime.now());
  bool get isCompleted => bookingStatus == 'completed';
  bool get isCancelled => bookingStatus == 'cancelled';
}
