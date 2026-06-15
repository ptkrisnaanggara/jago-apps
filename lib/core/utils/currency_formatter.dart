import 'package:intl/intl.dart';

/// Formats amounts as Indonesian Rupiah, e.g. `Rp 1.000.000`.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(num value) => _idr.format(value);
}
