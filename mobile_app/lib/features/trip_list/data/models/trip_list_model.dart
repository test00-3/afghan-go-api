import '../../../home/data/models/trip_model.dart';

class TripListModel {
  final List<TripModel> trips;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  TripListModel({
    required this.trips,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory TripListModel.fromJson(Map<String, dynamic> json) {
    return TripListModel(
      trips: (json['trips'] as List<dynamic>?)
              ?.map((trip) => TripModel.fromJson(trip))
              .toList() ??
          [],
      totalCount: json['total_count'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      hasMore: json['has_more'] ?? false,
    );
  }
}
