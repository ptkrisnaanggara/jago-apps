part of 'qris_bloc.dart';

sealed class QrisEvent extends Equatable {
  const QrisEvent();

  @override
  List<Object?> get props => [];
}

class QrisStarted extends QrisEvent {
  const QrisStarted();
}

class QrisParseRequested extends QrisEvent {
  final String payload;

  const QrisParseRequested(this.payload);

  @override
  List<Object?> get props => [payload];
}

class QrisPaid extends QrisEvent {
  final String? pocketId;
  final double? amount;

  const QrisPaid({this.pocketId, this.amount});

  @override
  List<Object?> get props => [pocketId, amount];
}
