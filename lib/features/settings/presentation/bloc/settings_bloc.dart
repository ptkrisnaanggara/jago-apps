import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/settings_store.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// Holds app-wide preferences (language + theme mode). Provided above
/// `MaterialApp.router` so the app rebuilds its locale/theme on change.
///
/// [initialState] is loaded from the store in `main.dart` before first paint
/// (no flash), and changes are written back through the [SettingsStore].
/// Defaults to an in-memory store so tests need no platform plugin.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsStore _store;

  SettingsBloc({
    SettingsStore? store,
    SettingsState initialState = const SettingsState(),
  })  : _store = store ?? InMemorySettingsStore(),
        super(initialState) {
    on<SettingsLocaleChanged>((event, emit) {
      emit(state.copyWith(locale: event.locale));
      _store.saveLocale(event.locale);
    });
    on<SettingsThemeModeChanged>((event, emit) {
      emit(state.copyWith(themeMode: event.themeMode));
      _store.saveThemeMode(event.themeMode);
    });
  }
}
