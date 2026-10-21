import 'package:intl/intl.dart';

class DateUtilsHelper {
  /// Converts a UTC date string to `dd-MM-yyyy` format
  static String formatDate(String dateString) {
    try {
      DateTime parsedDate;
      // Try ISO 8601 (with T and Z)
      if (RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(dateString)) {
        parsedDate = DateTime.parse(dateString).toLocal();
      } else if (dateString.contains('-')) {
        final parts = dateString.split('-');
        if (parts[0].length == 4) {
          parsedDate = DateTime.parse(dateString).toLocal();
        } else {
          parsedDate = DateFormat('dd-MM-yyyy').parse(dateString);
        }
      } else if (dateString.contains('/')) {
        parsedDate = DateFormat('dd/MM/yyyy').parse(dateString);
      } else {
        try {
          parsedDate = DateTime.parse(dateString).toLocal();
        } catch (_) {
          try {
            parsedDate = DateFormat('d MMMM yyyy').parse(dateString);
          } catch (e2) {
            return "Invalid Date";
          }
        }
      }
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }
}
