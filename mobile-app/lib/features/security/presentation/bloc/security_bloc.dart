import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/pin_store.dart';

part 'security_event.dart';
part 'security_state.dart';

/// Owns the app-lock PIN. Provided app-wide so `main.dart` can gate the UI
/// behind a lock screen when a PIN is set. The PIN is stored hashed (SHA-256).
class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  final PinStore _store;

  SecurityBloc({required PinStore store})
      : _store = store,
        super(const SecurityState()) {
    on<SecurityStarted>(_onStarted);
    on<PinCreated>(_onCreated);
    on<PinUnlockRequested>(_onUnlock);
    on<PinRemoved>(_onRemoved);
  }

  static String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> _onStarted(SecurityStarted event, Emitter<SecurityState> emit) async {
    final pinSet = await _store.readHash() != null;
    emit(state.copyWith(initialized: true, pinSet: pinSet, locked: pinSet));
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
    emit(state.copyWith(pinSet: false, locked: false, lastAttemptFailed: false));
  }
}
