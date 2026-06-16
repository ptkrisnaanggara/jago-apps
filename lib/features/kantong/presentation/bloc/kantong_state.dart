part of 'kantong_bloc.dart';

enum KantongStatus { initial, loading, success, failure }

class KantongState extends Equatable {
  final KantongStatus status;
  final List<Pocket> pockets;
  final AppFailure? failure;

  const KantongState({
    this.status = KantongStatus.initial,
    this.pockets = const [],
    this.failure,
  });

  double get totalBalance =>
      pockets.fold(0, (sum, p) => sum + p.balance);

  KantongState copyWith({
    KantongStatus? status,
    List<Pocket>? pockets,
    AppFailure? failure,
  }) {
    return KantongState(
      status: status ?? this.status,
      pockets: pockets ?? this.pockets,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, pockets, failure];
}
