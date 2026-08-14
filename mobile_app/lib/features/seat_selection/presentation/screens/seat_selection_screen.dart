import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../home/data/models/trip_model.dart';
import '../../data/models/seat_model.dart';
import '../widgets/seat_layout.dart';
import '../widgets/trip_info_header.dart';
import '../widgets/booking_bottom_bar.dart';
import '../../../booking/presentation/screens/booking_confirmation_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final TripModel trip;

  const SeatSelectionScreen({super.key, required this.trip});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<SeatModel> _seats = [];
  final List<SeatModel> _selectedSeats = [];
  bool _isLoading = true;
  bool _isVipMode = false;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  void _loadSeats() {
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _seats = _generateSeatLayout();
          _isLoading = false;
        });
      }
    });
  }

  List<SeatModel> _generateSeatLayout() {
    final List<SeatModel> seats = [];
    int seatNumber = 1;

    for (int row = 1; row <= 10; row++) {
      for (int col = 0; col < 4; col++) {
        final isVip = row <= 3;
        final isOccupied = _getOccupiedStatus(row, col);
        
        seats.add(SeatModel(
          id: 'seat_${row}_$col',
          row: row,
          column: col,
          label: seatNumber.toString().padLeft(2, '0'),
          status: isOccupied ? SeatStatus.occupied : SeatStatus.available,
          isVip: isVip,
          price: isVip ? widget.trip.vipPrice : widget.trip.normalPrice,
        ));
        
        seatNumber++;
      }
    }

    return seats;
  }

  bool _getOccupiedStatus(int row, int col) {
    final occupiedSeats = [
      [1, 0], [2, 1], [3, 3], [4, 0], [5, 2],
      [6, 1], [7, 3], [8, 0], [9, 2], [10, 1],
    ];
    return occupiedSeats.any((e) => e[0] == row && e[1] == col);
  }

  void _toggleSeat(SeatModel seat) {
    if (seat.isOccupied) return;

    setState(() {
      if (seat.isSelected) {
        _selectedSeats.removeWhere((s) => s.id == seat.id);
        final index = _seats.indexWhere((s) => s.id == seat.id);
        if (index != -1) {
          _seats[index] = seat.copyWith(status: SeatStatus.available);
        }
      } else {
        if (_selectedSeats.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('max_seats_warning')),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }
        _selectedSeats.add(seat);
        final index = _seats.indexWhere((s) => s.id == seat.id);
        if (index != -1) {
          _seats[index] = seat.copyWith(status: SeatStatus.selected);
        }
      }
    });
  }

  double get _totalPrice {
    return _selectedSeats.fold(0, (sum, seat) => sum + seat.price);
  }

  void _continueToBooking() {
    if (_selectedSeats.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          trip: widget.trip,
          selectedSeats: _selectedSeats,
          totalPrice: _totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('select_your_seats')),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TripInfoHeader(trip: widget.trip),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  else
                    SeatLayout(
                      seats: _seats,
                      onSeatTap: _toggleSeat,
                      seatsPerRow: 4,
                    ),
                ],
              ),
            ),
          ),
          BookingBottomBar(
            selectedCount: _selectedSeats.length,
            totalPrice: _totalPrice,
            onContinue: _continueToBooking,
          ),
        ],
      ),
    );
  }
}
