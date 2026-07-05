import 'package:intl/intl.dart';

/// Application-wide date formatting utilities.
///
/// All dates are formatted through this class to ensure consistency
/// across the entire app.
class DateFormatter {
  DateFormatter._();

  // ── Formatters ────────────────────────────────────────────────────────────

  /// Short date: "29 Jun 2026"
  static final DateFormat _shortDate = DateFormat('dd MMM yyyy', 'en_IN');

  /// Long date with time: "29 Jun 2026, 09:44 AM"
  static final DateFormat _longDateTime = DateFormat('dd MMM yyyy, hh:mm a', 'en_IN');

  /// Month + Year only: "Jun 2026"
  static final DateFormat _monthYear = DateFormat('MMM yyyy', 'en_IN');

  /// ISO date for API payloads: "2026-06-29"
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  // ── Public API ────────────────────────────────────────────────────────────

  /// Formats [date] as "29 Jun 2026". Returns '-' if null.
  static String toShortDate(DateTime? date) {
    if (date == null) return '-';
    return _shortDate.format(date);
  }

  /// Formats [date] as "29 Jun 2026, 09:44 AM". Returns '-' if null.
  static String toLongDateTime(DateTime? date) {
    if (date == null) return '-';
    return _longDateTime.format(date);
  }

  /// Formats [date] as "Jun 2026". Returns '-' if null.
  static String toMonthYear(DateTime? date) {
    if (date == null) return '-';
    return _monthYear.format(date);
  }

  /// Formats [date] as "2026-06-29" for API payloads. Returns '' if null.
  static String toIsoDate(DateTime? date) {
    if (date == null) return '';
    return _isoDate.format(date);
  }

  /// Parses an ISO date string. Returns null on failure.
  static DateTime? fromIsoString(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}
