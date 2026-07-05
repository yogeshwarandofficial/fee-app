import 'package:intl/intl.dart';

/// Formats monetary values as Indian Rupees with Indian digit grouping.
///
/// Examples:
///   formatINR(845000)   → '₹8,45,000'
///   formatINR(125000)   → '₹1,25,000'
///   formatINR(1500)     → '₹1,500'
///   formatINR(null)     → '₹0'
///   formatINR(double.nan) → '₹0'
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Formats [amount] as an Indian Rupee string.
  ///
  /// Safely handles null, NaN, Infinity, and negative-zero by falling back to ₹0.
  static String formatINR(num? amount) {
    if (amount == null) return '₹0';
    if (amount is double && (amount.isNaN || amount.isInfinite)) return '₹0';
    // Round to nearest integer — we never show fractional rupees.
    return _inrFormat.format(amount.round());
  }

  /// Parses a formatted INR string back to an integer, or returns 0 on failure.
  static int parseINR(String? formatted) {
    if (formatted == null || formatted.isEmpty) return 0;
    final cleaned = formatted.replaceAll(RegExp(r'[₹,\s]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}
