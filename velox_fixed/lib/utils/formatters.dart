import 'package:intl/intl.dart';

class Formatters {
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  static String formatShortDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }
}
