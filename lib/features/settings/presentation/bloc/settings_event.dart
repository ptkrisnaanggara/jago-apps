part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsLocaleChanged extends SettingsEvent {
  final Locale locale;

  const SettingsLocaleChanged(this.locale);

  @override
  List<Object?> get props => [locale];
}

class SettingsThemeModeChanged extends SettingsEvent {
  final ThemeMode themeMode;

  const SettingsThemeModeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}
