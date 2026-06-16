part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) all Home data.
class HomeStarted extends HomeEvent {
  const HomeStarted();
}
