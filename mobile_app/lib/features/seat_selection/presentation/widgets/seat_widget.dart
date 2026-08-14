import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../data/models/seat_model.dart';

class SeatWidget extends StatelessWidget {
  final SeatModel seat;
  final VoidCallback onTap;
  final double size;

  const SeatWidget({
    super.key,
    required this.seat,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    switch (seat.status) {
      case SeatStatus.available:
        if (seat.isVip) {
          backgroundColor = AppColors.vipBackground;
          borderColor = AppColors.accent;
          textColor = AppColors.accentDark;
        } else {
          backgroundColor = Colors.white;
          borderColor = Colors.grey.shade300;
          textColor = AppColors.textPrimary;
        }
        icon = null;
        break;
      case SeatStatus.selected:
        backgroundColor = AppColors.primary;
        borderColor = AppColors.primary;
        textColor = Colors.white;
        icon = Icons.check;
        break;
      case SeatStatus.occupied:
        backgroundColor = Colors.grey.shade200;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey.shade400;
        icon = Icons.close;
        break;
    }

    return GestureDetector(
      onTap: seat.isOccupied ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: seat.isSelected ? 2 : 1,
          ),
          boxShadow: seat.isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 16, color: textColor)
            else
              Text(
                seat.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            if (seat.isVip && seat.isAvailable)
              Icon(
                Icons.star,
                size: 10,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}
