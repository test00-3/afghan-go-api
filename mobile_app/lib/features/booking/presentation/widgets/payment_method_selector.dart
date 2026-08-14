import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String? selectedMethod;
  final ValueChanged<String?> onChanged;

  const PaymentMethodSelector({
    super.key,
    this.selectedMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('payment_method'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          context,
          id: 'hesabpay',
          title: l10n.translate('hesabpay'),
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF1B5E20),
        ),
        const SizedBox(height: 8),
        _buildPaymentOption(
          context,
          id: 'momo',
          title: l10n.translate('momo'),
          icon: Icons.phone_android,
          color: const Color(0xFFFF6F00),
        ),
        const SizedBox(height: 8),
        _buildPaymentOption(
          context,
          id: 'paypal',
          title: l10n.translate('paypal'),
          icon: Icons.payment,
          color: const Color(0xFF003087),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required String id,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedMethod == id;

    return GestureDetector(
      onTap: () => onChanged(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
