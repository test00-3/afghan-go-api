import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../../main.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              _getLanguageName(l10n.locale.languageCode),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          ],
        ),
      ),
      onSelected: (String languageCode) {
        Locale locale;
        switch (languageCode) {
          case 'fa':
            locale = const Locale('fa');
            break;
          case 'ps':
            locale = const Locale('ps');
            break;
          default:
            locale = const Locale('en');
        }
        AfghanBusApp.setLocale(context, locale);
      },
      itemBuilder: (BuildContext context) => [
        _buildLanguageItem('en', 'English', '🇺🇸'),
        _buildLanguageItem('fa', 'دری', '🇦🇫'),
        _buildLanguageItem('ps', 'پښتو', '🇦🇫'),
      ],
    );
  }

  PopupMenuItem<String> _buildLanguageItem(
    String code,
    String name,
    String flag,
  ) {
    return PopupMenuItem(
      value: code,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fa':
        return 'دری';
      case 'ps':
        return 'پښتو';
      default:
        return 'EN';
    }
  }
}
