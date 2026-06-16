import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/settings/data/settings_store.dart';
import 'package:jago/features/settings/presentation/bloc/settings_bloc.dart';

void main() {
  group('SettingsBloc', () {
    test('defaults to Indonesian locale and system theme', () {
      final bloc = SettingsBloc();
      expect(bloc.state.locale, const Locale('id'));
      expect(bloc.state.themeMode, ThemeMode.system);
    });

    test('honours the persisted initialState', () {
      final bloc = SettingsBloc(
        initialState: const SettingsState(
          locale: Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      expect(bloc.state.locale, const Locale('en'));
      expect(bloc.state.themeMode, ThemeMode.dark);
    });

    test('writes locale + theme changes back to the store', () async {
      final store = InMemorySettingsStore();
      final bloc = SettingsBloc(store: store);

      bloc
        ..add(const SettingsLocaleChanged(Locale('en')))
        ..add(const SettingsThemeModeChanged(ThemeMode.dark));
      await Future<void>.delayed(Duration.zero);

      final snapshot = await store.read();
      expect(snapshot.locale, const Locale('en'));
      expect(snapshot.themeMode, ThemeMode.dark);
    });

    blocTest<SettingsBloc, SettingsState>(
      'changes locale to English',
      build: SettingsBloc.new,
      act: (bloc) => bloc.add(const SettingsLocaleChanged(Locale('en'))),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.locale, 'locale', const Locale('en')),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'changes theme mode to dark',
      build: SettingsBloc.new,
      act: (bloc) => bloc.add(const SettingsThemeModeChanged(ThemeMode.dark)),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.themeMode, 'themeMode', ThemeMode.dark),
      ],
    );
  });
}
