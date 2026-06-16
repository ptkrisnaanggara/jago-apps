part of 'topup_bloc.dart';

enum TopupStatus { initial, loading, ready, purchasing, success, failure }

class TopupState extends Equatable {
  final TopupStatus status;
  final List<TopupProduct> products;
  final List<Pocket> pockets;
  final TopupReceipt? receipt;
  final AppFailure? failure;

  const TopupState({
    this.status = TopupStatus.initial,
    this.products = const [],
    this.pockets = const [],
    this.receipt,
    this.failure,
  });

  TopupState copyWith({
    TopupStatus? status,
    List<TopupProduct>? products,
    List<Pocket>? pockets,
    TopupReceipt? receipt,
    AppFailure? failure,
  }) {
    return TopupState(
      status: status ?? this.status,
      products: products ?? this.products,
      pockets: pockets ?? this.pockets,
      receipt: receipt ?? this.receipt,
      // failure resets each transition unless set explicitly.
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, products, pockets, receipt, failure];
}
