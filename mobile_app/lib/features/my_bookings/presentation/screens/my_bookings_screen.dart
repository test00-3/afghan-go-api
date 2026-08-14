import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../widgets/booking_ticket_card.dart';
import '../../data/models/my_booking_model.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MyBookingModel> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadBookings() {
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _bookings = _generateMockBookings();
          _isLoading = false;
        });
      }
    });
  }

  List<MyBookingModel> _generateMockBookings() {
    final now = DateTime.now();
    return [
      MyBookingModel(
        id: 'BK001',
        tripId: 'T001',
        origin: 'Kabul',
        destination: 'Herat',
        tripDate: now.add(const Duration(days: 2)),
        departureTime: DateTime(now.year, now.month, now.day + 2, 6, 0),
        arrivalTime: DateTime(now.year, now.month, now.day + 2, 12, 0),
        companyName: 'Afghan Express',
        busType: 'standard',
        seatNumbers: ['12', '13'],
        totalAmount: 900,
        paidAmount: 180,
        paymentMethod: 'hesabpay',
        paymentStatus: 'completed',
        bookingStatus: 'confirmed',
        bookingDate: now.subtract(const Duration(days: 1)),
      ),
      MyBookingModel(
        id: 'BK002',
        tripId: 'T002',
        origin: 'Mazar-i-Sharif',
        destination: 'Kabul',
        tripDate: now.add(const Duration(days: 5)),
        departureTime: DateTime(now.year, now.month, now.day + 5, 8, 0),
        arrivalTime: DateTime(now.year, now.month, now.day + 5, 14, 0),
        companyName: 'VIP Transport',
        busType: 'vip',
        seatNumbers: ['5'],
        totalAmount: 850,
        paidAmount: 850,
        paymentMethod: 'momo',
        paymentStatus: 'completed',
        bookingStatus: 'confirmed',
        bookingDate: now.subtract(const Duration(days: 3)),
      ),
      MyBookingModel(
        id: 'BK003',
        tripId: 'T003',
        origin: 'Herat',
        destination: 'Kandahar',
        tripDate: now.subtract(const Duration(days: 7)),
        departureTime: DateTime(now.year, now.month, now.day - 7, 10, 0),
        arrivalTime: DateTime(now.year, now.month, now.day - 7, 16, 0),
        companyName: 'Herat Stars',
        busType: 'standard',
        seatNumbers: ['20', '21'],
        totalAmount: 760,
        paidAmount: 760,
        paymentMethod: 'paypal',
        paymentStatus: 'completed',
        bookingStatus: 'completed',
        bookingDate: now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  List<MyBookingModel> get _upcomingBookings =>
      _bookings.where((b) => b.isUpcoming).toList();

  List<MyBookingModel> get _completedBookings =>
      _bookings.where((b) => b.isCompleted).toList();

  List<MyBookingModel> get _cancelledBookings =>
      _bookings.where((b) => b.isCancelled).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('my_bookings_title')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: l10n.translate('upcoming')),
            Tab(text: l10n.translate('completed')),
            Tab(text: l10n.translate('cancelled')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_upcomingBookings, l10n),
                _buildBookingsList(_completedBookings, l10n),
                _buildBookingsList(_cancelledBookings, l10n),
              ],
            ),
    );
  }

  Widget _buildBookingsList(
    List<MyBookingModel> bookings,
    AppLocalizations l10n,
  ) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('no_bookings'),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingTicketCard(
          booking: booking,
          onCancel: booking.isUpcoming
              ? () {
                  setState(() {
                    _bookings = _bookings.map((b) {
                      if (b.id == booking.id) {
                        return MyBookingModel.fromJson({
                          ...b.toJson(),
                          'booking_status': 'cancelled',
                        });
                      }
                      return b;
                    }).toList();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('booking_cancelled')),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}
