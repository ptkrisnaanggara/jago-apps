part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final Locale locale;
  final ThemeMode themeMode;

  /// Defaults: Bahasa Indonesia (PRD primary) + follow the system theme.
  const SettingsState({
    this.locale = const Locale('id'),
    this.themeMode = ThemeMode.system,
  });

  SettingsState copyWith({Locale? locale, ThemeMode? themeMode}) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [locale, themeMode];
}
