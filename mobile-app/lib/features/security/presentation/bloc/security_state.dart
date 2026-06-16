part of 'security_bloc.dart';

class SecurityState extends Equatable {
  /// True once [SecurityStarted] has resolved.
  final bool initialized;
  final bool pinSet;
  final bool locked;
  final bool lastAttemptFailed;

  const SecurityState({
    this.initialized = false,
    this.pinSet = false,
    this.locked = false,
    this.lastAttemptFailed = false,
  });

  SecurityState copyWith({
    bool? initialized,
    bool? pinSet,
    bool? locked,
    bool? lastAttemptFailed,
  }) {
    return SecurityState(
      initialized: initialized ?? this.initialized,
      pinSet: pinSet ?? this.pinSet,
      locked: locked ?? this.locked,
      lastAttemptFailed: lastAttemptFailed ?? this.lastAttemptFailed,
    );
  }

  @override
  List<Object?> get props => [initialized, pinSet, locked, lastAttemptFailed];
}
