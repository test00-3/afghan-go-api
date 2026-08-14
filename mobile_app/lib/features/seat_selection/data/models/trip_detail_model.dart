class TripDetailModel {
  final String tripId;
  final String companyName;
  final String companyLogo;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String busType;
  final String driverName;
  final String? driverPhone;
  final double normalPrice;
  final double vipPrice;
  final int totalRows;
  final int seatsPerRow;
  final List<List<SeatInfo>> seatLayout;

  TripDetailModel({
    required this.tripId,
    required this.companyName,
    required this.companyLogo,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.busType,
    required this.driverName,
    this.driverPhone,
    required this.normalPrice,
    required this.vipPrice,
    required this.totalRows,
    required this.seatsPerRow,
    required this.seatLayout,
  });

  factory TripDetailModel.fromJson(Map<String, dynamic> json) {
    return TripDetailModel(
      tripId: json['trip_id'] ?? '',
      companyName: json['company_name'] ?? '',
      companyLogo: json['company_logo'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      departureTime: DateTime.parse(json['departure_time'] ?? DateTime.now().toIso8601String()),
      arrivalTime: DateTime.parse(json['arrival_time'] ?? DateTime.now().toIso8601String()),
      busType: json['bus_type'] ?? 'standard',
      driverName: json['driver_name'] ?? '',
      driverPhone: json['driver_phone'],
      normalPrice: (json['normal_price'] ?? 0).toDouble(),
      vipPrice: (json['vip_price'] ?? 0).toDouble(),
      totalRows: json['total_rows'] ?? 10,
      seatsPerRow: json['seats_per_row'] ?? 4,
      seatLayout: (json['seat_layout'] as List<dynamic>?)
              ?.map((row) => (row as List<dynamic>)
                  .map((seat) => SeatInfo.fromJson(seat))
                  .toList())
              .toList() ??
          [],
    );
  }
}

class SeatInfo {
  final String id;
  final int row;
  final int col;
  final String label;
  final bool isOccupied;
  final bool isVip;
  final double price;

  SeatInfo({
    required this.id,
    required this.row,
    required this.col,
    required this.label,
    required this.isOccupied,
    required this.isVip,
    required this.price,
  });

  factory SeatInfo.fromJson(Map<String, dynamic> json) {
    return SeatInfo(
      id: json['id'] ?? '',
      row: json['row'] ?? 0,
      col: json['col'] ?? 0,
      label: json['label'] ?? '',
      isOccupied: json['is_occupied'] ?? false,
      isVip: json['is_vip'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
