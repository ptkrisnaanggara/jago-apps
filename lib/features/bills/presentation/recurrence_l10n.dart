import 'package:jago/l10n/app_localizations.dart';

import '../data/models/bill.dart';

/// Localized label for a [BillRecurrence] (keeps display text out of the model).
String recurrenceLabel(AppLocalizations l10n, BillRecurrence recurrence) {
  return switch (recurrence) {
    BillRecurrence.none => l10n.recurrenceOnce,
    BillRecurrence.weekly => l10n.recurrenceWeekly,
    BillRecurrence.monthly => l10n.recurrenceMonthly,
  };
}
