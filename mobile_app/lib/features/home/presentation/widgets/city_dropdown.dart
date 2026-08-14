import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';

class CityDropdown extends StatelessWidget {
  final String? value;
  final String hintText;
  final ValueChanged<String?> onChanged;
  final String? excludeCity;

  const CityDropdown({
    super.key,
    this.value,
    required this.hintText,
    required this.onChanged,
    this.excludeCity,
  });

  static const Map<String, String> _cityKeys = {
    'Kabul': 'kabul',
    'Herat': 'herat',
    'Mazar-i-Sharif': 'mazar_i_sharif',
    'Kandahar': 'kandahar',
    'Kunduz': 'kunduz',
    'Jalalabad': 'jalalabad',
    'Bamyan': 'bamyan',
    'Maimana': 'maimana',
    'Gardez': 'gardez',
    'Farah': 'farah',
    'Zaranj': 'zaranj',
    'Taloqan': 'taloqan',
    'Pul-e-Khumri': 'pul_e_khumri',
    'Charikar': 'charikar',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cities = _cityKeys.entries
        .where((e) => e.key != excludeCity)
        .map((e) => e.key)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          hintText,
          style: TextStyle(color: Colors.grey.shade500),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
        ),
        items: cities.map((String city) {
          final key = _cityKeys[city]!;
          return DropdownMenuItem(
            value: city,
            child: Text(
              l10n.translate(key),
              style: const TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
