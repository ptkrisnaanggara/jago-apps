import 'package:flutter/widgets.dart';
import 'package:jago/l10n/app_localizations.dart';

import 'app_failure.dart';

/// Maps an [AppFailure] code to localized, user-facing text. Keeping this in
/// the UI layer is what lets blocs stay free of display strings.
String failureText(BuildContext context, AppFailure failure) {
  final l10n = AppLocalizations.of(context)!;
  return switch (failure) {
    AppFailure.generic => l10n.genericError,
    AppFailure.otpSendFailed => l10n.errorOtpSend,
    AppFailure.otpInvalid => l10n.errorOtpInvalid,
    AppFailure.loadContactsFailed => l10n.errorLoadContacts,
    AppFailure.transferFailed => l10n.errorTransfer,
    AppFailure.loadBillsFailed => l10n.errorLoadBills,
    AppFailure.payBillFailed => l10n.errorPayBill,
    AppFailure.scheduleBillFailed => l10n.errorScheduleBill,
    AppFailure.loadTransactionsFailed => l10n.errorLoadTransactions,
    AppFailure.loadPocketsFailed => l10n.errorLoadPockets,
    AppFailure.pocketActionFailed => l10n.errorPocketAction,
    AppFailure.loadCardsFailed => l10n.errorLoadCards,
    AppFailure.updateCardFailed => l10n.errorUpdateCard,
    AppFailure.loadNotificationsFailed => l10n.errorLoadNotifications,
    AppFailure.loadAccountFailed => l10n.errorLoadData,
    AppFailure.qrisFailed => l10n.errorQris,
    AppFailure.topupFailed => l10n.errorTopup,
  };
}
