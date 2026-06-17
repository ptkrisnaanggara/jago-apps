part of 'qris_bloc.dart';

enum QrisStatus { initial, loading, ready, parsing, review, paying, success, failure }

class QrisState extends Equatable {
  final QrisStatus status;
  final List<Pocket> pockets;
  final String payload;
  final QrisInfo? info;
  final QrisReceipt? receipt;
  final AppFailure? failure;

  const QrisState({
    this.status = QrisStatus.initial,
    this.pockets = const [],
    this.payload = '',
    this.info,
    this.receipt,
    this.failure,
  });

  QrisState copyWith({
    QrisStatus? status,
    List<Pocket>? pockets,
    String? payload,
    QrisInfo? info,
    QrisReceipt? receipt,
    AppFailure? failure,
  }) {
    return QrisState(
      status: status ?? this.status,
      pockets: pockets ?? this.pockets,
      payload: payload ?? this.payload,
      info: info ?? this.info,
      receipt: receipt ?? this.receipt,
      // failure resets each transition unless set explicitly.
      failure: failure,
    );
  }

  @override
  List<Object?> get props =>
      [status, pockets, payload, info, receipt, failure];
}
