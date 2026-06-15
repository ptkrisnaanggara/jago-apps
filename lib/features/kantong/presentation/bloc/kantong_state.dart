part of 'kantong_bloc.dart';

enum KantongStatus { initial, loading, success, failure }

class KantongState extends Equatable {
  final KantongStatus status;
  final List<Pocket> pockets;
  final String? errorMessage;

  const KantongState({
    this.status = KantongStatus.initial,
    this.pockets = const [],
    this.errorMessage,
  });

  double get totalBalance =>
      pockets.fold(0, (sum, p) => sum + p.balance);

  KantongState copyWith({
    KantongStatus? status,
    List<Pocket>? pockets,
    String? errorMessage,
  }) {
    return KantongState(
      status: status ?? this.status,
      pockets: pockets ?? this.pockets,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, pockets, errorMessage];
}
