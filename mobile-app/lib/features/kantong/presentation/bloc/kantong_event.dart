part of 'kantong_bloc.dart';

sealed class KantongEvent extends Equatable {
  const KantongEvent();

  @override
  List<Object?> get props => [];
}

class KantongStarted extends KantongEvent {
  const KantongStarted();
}
