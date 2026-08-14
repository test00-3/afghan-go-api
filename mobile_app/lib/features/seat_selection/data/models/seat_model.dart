enum SeatStatus { available, selected, occupied }

class SeatModel {
  final String id;
  final int row;
  final int column;
  final String label;
  final SeatStatus status;
  final bool isVip;
  final double price;
  final String? passengerName;

  SeatModel({
    required this.id,
    required this.row,
    required this.column,
    required this.label,
    this.status = SeatStatus.available,
    this.isVip = false,
    required this.price,
    this.passengerName,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      id: json['id'] ?? '',
      row: json['row'] ?? 0,
      column: json['column'] ?? 0,
      label: json['label'] ?? '',
      status: SeatStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SeatStatus.available,
      ),
      isVip: json['is_vip'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
      passengerName: json['passenger_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'row': row,
      'column': column,
      'label': label,
      'status': status.name,
      'is_vip': isVip,
      'price': price,
      'passenger_name': passengerName,
    };
  }

  SeatModel copyWith({
    String? id,
    int? row,
    int? column,
    String? label,
    SeatStatus? status,
    bool? isVip,
    double? price,
    String? passengerName,
  }) {
    return SeatModel(
      id: id ?? this.id,
      row: row ?? this.row,
      column: column ?? this.column,
      label: label ?? this.label,
      status: status ?? this.status,
      isVip: isVip ?? this.isVip,
      price: price ?? this.price,
      passengerName: passengerName ?? this.passengerName,
    );
  }

  bool get isAvailable => status == SeatStatus.available;
  bool get isSelected => status == SeatStatus.selected;
  bool get isOccupied => status == SeatStatus.occupied;
}
