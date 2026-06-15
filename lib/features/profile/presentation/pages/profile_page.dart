import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

/// Profile tab. Personal info comes from the authenticated [AuthUser];
/// language & theme are wired to [SettingsBloc] (PRD §3 P2 #10).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final settings = context.watch<SettingsBloc>().state;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person_rounded,
                        size: 44, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Nasabah Jago',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    user == null ? '' : '+62 ${user.phone}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SettingTile(icon: Icons.lock_outline, label: l10n.settingSecurity),
            _SettingTile(
              icon: Icons.language_outlined,
              label: l10n.settingLanguage,
              value: _languageName(l10n, settings.locale),
              onTap: () => _pickLanguage(context),
            ),
            _SettingTile(
              icon: Icons.dark_mode_outlined,
              label: l10n.settingAppearance,
              value: _themeModeName(l10n, settings.themeMode),
              onTap: () => _pickAppearance(context),
            ),
            _SettingTile(
                icon: Icons.help_outline_rounded, label: l10n.settingHelp),
            _SettingTile(
              icon: Icons.logout_rounded,
              label: l10n.signOut,
              onTap: () => _confirmSignOut(context),
            ),
          ],
        ),
      ),
    );
  }

  static String _languageName(AppLocalizations l10n, Locale locale) =>
      locale.languageCode == 'en'
          ? l10n.languageEnglish
          : l10n.languageIndonesian;

  static String _themeModeName(AppLocalizations l10n, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.system => l10n.appearanceSystem,
        ThemeMode.light => l10n.appearanceLight,
        ThemeMode.dark => l10n.appearanceDark,
      };

  Future<void> _pickLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<SettingsBloc>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _OptionSheet<Locale>(
        title: l10n.chooseLanguage,
        groupValue: bloc.state.locale,
        options: [
          (const Locale('id'), l10n.languageIndonesian),
          (const Locale('en'), l10n.languageEnglish),
        ],
        onSelected: (locale) {
          bloc.add(SettingsLocaleChanged(locale));
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _pickAppearance(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<SettingsBloc>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _OptionSheet<ThemeMode>(
        title: l10n.chooseAppearance,
        groupValue: bloc.state.themeMode,
        options: [
          (ThemeMode.system, l10n.appearanceSystem),
          (ThemeMode.light, l10n.appearanceLight),
          (ThemeMode.dark, l10n.appearanceDark),
        ],
        onSelected: (mode) {
          bloc.add(SettingsThemeModeChanged(mode));
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthSignedOut());
    }
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey,
                  ),
            ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap ?? () {},
    );
  }
}

/// A simple radio-style picker rendered in a bottom sheet.
class _OptionSheet<T> extends StatelessWidget {
  final String title;
  final T groupValue;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;

  const _OptionSheet({
    required this.title,
    required this.groupValue,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final (value, label) in options)
            ListTile(
              title: Text(label),
              trailing: value == groupValue
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => onSelected(value),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
