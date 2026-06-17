import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/security_bloc.dart';

/// Set / change / remove the app-lock PIN (Profile → Security).
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _save() {
    final pin = _pin.text.trim();
    if (pin.length != 6) return;
    context.read<SecurityBloc>().add(PinCreated(pin));
    _pin.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('PIN ✓')));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sec = context.watch<SecurityBloc>().state;
    final pinSet = sec.pinSet;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingSecurity)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.defaultMargin),
          children: [
            Text(pinSet ? l10n.pinChangeTitle : l10n.pinSetTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.pinEnterLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _save, child: Text(l10n.pinSave)),
            if (pinSet) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () =>
                    context.read<SecurityBloc>().add(const PinRemoved()),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error),
                child: Text(l10n.pinRemove),
              ),
              if (sec.biometricAvailable) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.securityBiometric),
                  value: sec.biometricEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) =>
                      context.read<SecurityBloc>().add(BiometricToggled(v)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
