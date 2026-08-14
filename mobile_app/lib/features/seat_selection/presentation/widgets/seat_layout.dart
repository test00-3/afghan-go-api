import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../data/models/seat_model.dart';
import 'seat_widget.dart';

class SeatLayout extends StatelessWidget {
  final List<SeatModel> seats;
  final ValueChanged<SeatModel> onSeatTap;
  final int seatsPerRow;

  const SeatLayout({
    super.key,
    required this.seats,
    required this.onSeatTap,
    this.seatsPerRow = 4,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = _groupSeatsByRow();

    return Column(
      children: [
        Container(
          width: 80,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.directions_bus,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
              l10n.translate('available'),
              Colors.white,
              Colors.grey.shade300,
            ),
            _buildLegendItem(
              l10n.translate('selected'),
              AppColors.primary,
              AppColors.primary,
            ),
            _buildLegendItem(
              l10n.translate('occupied'),
              Colors.grey.shade200,
              Colors.grey.shade300,
            ),
            _buildLegendItem(
              l10n.translate('vip_seat'),
              AppColors.vipBackground,
              AppColors.accent,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...rows.map((row) => _buildSeatRow(row, context)),
      ],
    );
  }

  List<List<SeatModel>> _groupSeatsByRow() {
    final Map<int, List<SeatModel>> rowMap = {};
    for (final seat in seats) {
      rowMap.putIfAbsent(seat.row, () => []).add(seat);
    }
    
    final rows = rowMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return rows.map((e) => e.value.toList()..sort((a, b) => a.column.compareTo(b.column))).toList();
  }

  Widget _buildSeatRow(List<SeatModel> rowSeats, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final leftSeats = rowSeats.where((s) => s.column < 2).toList();
    final rightSeats = rowSeats.where((s) => s.column >= 2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...leftSeats.map((seat) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: SeatWidget(
              seat: seat,
              onTap: () => onSeatTap(seat),
            ),
          )),
          Container(
            width: 24,
            height: 44,
            alignment: Alignment.center,
            child: Text(
              l10n.translate('aisle'),
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...rightSeats.map((seat) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: SeatWidget(
              seat: seat,
              onTap: () => onSeatTap(seat),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, Color borderColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
