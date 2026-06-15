import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// Holds app-wide preferences (language + theme mode). Provided above
/// `MaterialApp.router` so the app rebuilds its locale/theme on change.
///
/// In-memory for now (consistent with the other mock-backed state); persisting
/// via `shared_preferences` is a documented follow-up (PRD §5).
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<SettingsLocaleChanged>(
      (event, emit) => emit(state.copyWith(locale: event.locale)),
    );
    on<SettingsThemeModeChanged>(
      (event, emit) => emit(state.copyWith(themeMode: event.themeMode)),
    );
  }
}
