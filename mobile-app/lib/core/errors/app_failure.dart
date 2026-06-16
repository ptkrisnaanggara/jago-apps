/// Feature-agnostic failure codes emitted by blocs. Display text is resolved
/// in the UI via `failureText` so blocs never hold localized strings
/// (PRD §5: `core/errors`).
enum AppFailure {
  generic,
  otpSendFailed,
  otpInvalid,
  loadContactsFailed,
  transferFailed,
  loadBillsFailed,
  payBillFailed,
  scheduleBillFailed,
  loadTransactionsFailed,
  loadPocketsFailed,
  pocketActionFailed,
  loadCardsFailed,
  updateCardFailed,
  loadNotificationsFailed,
  loadAccountFailed,
  qrisFailed,
  topupFailed,
}
