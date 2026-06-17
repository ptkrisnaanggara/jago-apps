import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/biometric_auth.dart';
import '../../data/pin_store.dart';

part 'security_event.dart';
part 'security_state.dart';

/// Owns the app-lock PIN + biometric unlock. Provided app-wide so `main.dart`
/// can gate the UI behind a lock screen when a PIN is set. The PIN is stored
/// hashed (SHA-256).
class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  final PinStore _store;
  final BiometricAuth _biometric;

  SecurityBloc({required PinStore store, required BiometricAuth biometric})
      : _store = store,
        _biometric = biometric,
        super(const SecurityState()) {
    on<SecurityStarted>(_onStarted);
    on<PinCreated>(_onCreated);
    on<PinUnlockRequested>(_onUnlock);
    on<PinRemoved>(_onRemoved);
    on<BiometricToggled>(_onBiometricToggled);
    on<BiometricUnlockRequested>(_onBiometricUnlock);
  }

  static String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> _onStarted(SecurityStarted event, Emitter<SecurityState> emit) async {
    final pinSet = await _store.readHash() != null;
    emit(state.copyWith(
      initialized: true,
      pinSet: pinSet,
      locked: pinSet,
      biometricAvailable: await _biometric.isAvailable(),
      biometricEnabled: await _store.readBiometricEnabled(),
    ));
  }

  Future<void> _onCreated(PinCreated event, Emitter<SecurityState> emit) async {
    await _store.saveHash(_hash(event.pin));
    emit(state.copyWith(pinSet: true, locked: false, lastAttemptFailed: false));
  }

  Future<void> _onUnlock(PinUnlockRequested event, Emitter<SecurityState> emit) async {
    final stored = await _store.readHash();
    if (stored != null && stored == _hash(event.pin)) {
      emit(state.copyWith(locked: false, lastAttemptFailed: false));
    } else {
      emit(state.copyWith(lastAttemptFailed: true));
    }
  }

  Future<void> _onRemoved(PinRemoved event, Emitter<SecurityState> emit) async {
    await _store.clear();
    emit(state.copyWith(
        pinSet: false, locked: false, biometricEnabled: false, lastAttemptFailed: false));
  }

  Future<void> _onBiometricToggled(
    BiometricToggled event,
    Emitter<SecurityState> emit,
  ) async {
    // Only allow enabling when the device actually supports biometrics.
    final enabled = event.enabled && state.biometricAvailable;
    await _store.saveBiometricEnabled(enabled);
    emit(state.copyWith(biometricEnabled: enabled));
  }

  Future<void> _onBiometricUnlock(
    BiometricUnlockRequested event,
    Emitter<SecurityState> emit,
  ) async {
    if (!state.biometricEnabled) return;
    final ok = await _biometric.authenticate('Buka aplikasi Jago');
    if (ok) {
      emit(state.copyWith(locked: false, lastAttemptFailed: false));
    }
  }
}
