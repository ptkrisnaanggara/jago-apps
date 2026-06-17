part of 'security_bloc.dart';

sealed class SecurityEvent extends Equatable {
  const SecurityEvent();

  @override
  List<Object?> get props => [];
}

/// Load whether a PIN exists (and lock if so) on app start.
class SecurityStarted extends SecurityEvent {
  const SecurityStarted();
}

class PinCreated extends SecurityEvent {
  final String pin;

  const PinCreated(this.pin);

  @override
  List<Object?> get props => [pin];
}

class PinUnlockRequested extends SecurityEvent {
  final String pin;

  const PinUnlockRequested(this.pin);

  @override
  List<Object?> get props => [pin];
}

class PinRemoved extends SecurityEvent {
  const PinRemoved();
}

class BiometricToggled extends SecurityEvent {
  final bool enabled;

  const BiometricToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class BiometricUnlockRequested extends SecurityEvent {
  const BiometricUnlockRequested();
}
