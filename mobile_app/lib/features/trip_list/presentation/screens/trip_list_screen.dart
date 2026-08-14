import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/trip_card.dart';
import '../../data/models/trip_model.dart';

class TripListScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime date;

  const TripListScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
  });

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  List<TripModel> _trips = [];
  bool _isLoading = true;
  String _sortBy = 'departure_time';
  bool _vipOnly = false;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _trips = _generateMockTrips();
          _isLoading = false;
        });
      }
    });
  }

  List<TripModel> _generateMockTrips() {
    final now = DateTime.now();
    return [
      TripModel(
        id: '1',
        companyId: 'c1',
        companyName: 'Afghan Express',
        origin: widget.origin,
        destination: widget.destination,
        departureTime: DateTime(now.year, now.month, now.day, 6, 0),
        arrivalTime: DateTime(now.year, now.month, now.day, 12, 0),
        normalPrice: 450,
        vipPrice: 750,
        totalSeats: 40,
        availableSeats: 15,
        busType: 'standard',
        driverName: 'Ahmad Khan',
      ),
      TripModel(
        id: '2',
        companyId: 'c2',
        companyName: 'VIP Transport',
        origin: widget.origin,
        destination: widget.destination,
        departureTime: DateTime(now.year, now.month, now.day, 7, 30),
        arrivalTime: DateTime(now.year, now.month, now.day, 13, 0),
        normalPrice: 500,
        vipPrice: 850,
        totalSeats: 35,
        availableSeats: 8,
        busType: 'vip',
        driverName: 'Mohammad Ali',
      ),
      TripModel(
        id: '3',
        companyId: 'c3',
        companyName: 'Kabul Bus Co.',
        origin: widget.origin,
        destination: widget.destination,
        departureTime: DateTime(now.year, now.month, now.day, 9, 0),
        arrivalTime: DateTime(now.year, now.month, now.day, 15, 30),
        normalPrice: 400,
        vipPrice: 700,
        totalSeats: 45,
        availableSeats: 22,
        busType: 'standard',
        driverName: 'Gul Ahmad',
      ),
      TripModel(
        id: '4',
        companyId: 'c4',
        companyName: 'Herat Stars',
        origin: widget.origin,
        destination: widget.destination,
        departureTime: DateTime(now.year, now.month, now.day, 10, 0),
        arrivalTime: DateTime(now.year, now.month, now.day, 16, 0),
        normalPrice: 480,
        vipPrice: 800,
        totalSeats: 40,
        availableSeats: 0,
        busType: 'standard',
        driverName: 'Bismillah',
      ),
      TripModel(
        id: '5',
        companyId: 'c5',
        companyName: 'Northern Lines',
        origin: widget.origin,
        destination: widget.destination,
        departureTime: DateTime(now.year, now.month, now.day, 14, 0),
        arrivalTime: DateTime(now.year, now.month, now.day, 20, 0),
        normalPrice: 420,
        vipPrice: 720,
        totalSeats: 40,
        availableSeats: 18,
        busType: 'standard',
        driverName: 'Najibullah',
      ),
    ];
  }

  List<TripModel> get _filteredTrips {
    var trips = List<TripModel>.from(_trips);
    
    if (_vipOnly) {
      trips = trips.where((t) => t.isVip).toList();
    }

    switch (_sortBy) {
      case 'price_low':
        trips.sort((a, b) => a.normalPrice.compareTo(b.normalPrice));
        break;
      case 'price_high':
        trips.sort((a, b) => b.normalPrice.compareTo(a.normalPrice));
        break;
      case 'departure_time':
        trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
    }

    return trips;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('available_trips')),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.origin} → ${widget.destination}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Formatters.formatDate(widget.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_filteredTrips.length} ${l10n.translate('trips_found')}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_filteredTrips.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bus_alert,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.translate('no_trips_found'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredTrips.length,
                itemBuilder: (context, index) {
                  return TripCard(trip: _filteredTrips[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final l10n = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('filter'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.translate('sort_by'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        l10n.translate('departure_time'),
                        _sortBy == 'departure_time',
                        () => setModalState(() => _sortBy = 'departure_time'),
                      ),
                      _buildFilterChip(
                        l10n.translate('price_low_high'),
                        _sortBy == 'price_low',
                        () => setModalState(() => _sortBy = 'price_low'),
                      ),
                      _buildFilterChip(
                        l10n.translate('price_high_low'),
                        _sortBy == 'price_high',
                        () => setModalState(() => _sortBy = 'price_high'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: Text(l10n.translate('vip_only')),
                    value: _vipOnly,
                    onChanged: (value) {
                      setModalState(() => _vipOnly = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(l10n.translate('confirm')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
