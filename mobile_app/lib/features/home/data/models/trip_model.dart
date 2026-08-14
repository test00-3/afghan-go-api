class TripModel {
  final String id;
  final String companyId;
  final String companyName;
  final String? companyLogo;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double normalPrice;
  final double vipPrice;
  final int totalSeats;
  final int availableSeats;
  final String busType;
  final String driverName;
  final String? driverPhone;
  final String status;

  TripModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.companyLogo,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.normalPrice,
    required this.vipPrice,
    required this.totalSeats,
    required this.availableSeats,
    required this.busType,
    required this.driverName,
    this.driverPhone,
    this.status = 'active',
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      companyName: json['company_name'] ?? '',
      companyLogo: json['company_logo'],
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      departureTime: DateTime.parse(json['departure_time'] ?? DateTime.now().toIso8601String()),
      arrivalTime: DateTime.parse(json['arrival_time'] ?? DateTime.now().toIso8601String()),
      normalPrice: (json['normal_price'] ?? 0).toDouble(),
      vipPrice: (json['vip_price'] ?? 0).toDouble(),
      totalSeats: json['total_seats'] ?? 0,
      availableSeats: json['available_seats'] ?? 0,
      busType: json['bus_type'] ?? 'standard',
      driverName: json['driver_name'] ?? '',
      driverPhone: json['driver_phone'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'company_name': companyName,
      'company_logo': companyLogo,
      'origin': origin,
      'destination': destination,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'normal_price': normalPrice,
      'vip_price': vipPrice,
      'total_seats': totalSeats,
      'available_seats': availableSeats,
      'bus_type': busType,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'status': status,
    };
  }

  Duration get duration => arrivalTime.difference(departureTime);
  bool get isVip => busType.toLowerCase() == 'vip';
  bool get isFullyBooked => availableSeats == 0;
}
