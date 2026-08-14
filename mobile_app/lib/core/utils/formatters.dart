import 'package:intl/intl.dart';

class Formatters {
  static String formatPrice(double price, {String currency = 'AFN'}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(price.toInt())} $currency';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static String formatPhoneNumber(String phone) {
    if (phone.length == 10) {
      return '+93 ${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }

  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  static String formatBookingId(String id) {
    return 'BK-${id.toUpperCase()}';
  }
}
