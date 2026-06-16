import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/security_bloc.dart';

/// Full-screen app lock shown (over the whole app) while a PIN is set and the
/// session is locked.
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.length == 6) {
      context.read<SecurityBloc>().add(PinUnlockRequested(value));
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failed =
        context.select((SecurityBloc b) => b.state.lastAttemptFailed);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 56, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(l10n.pinLockSubtitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                obscureText: true,
                maxLength: 6,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(letterSpacing: 16),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                  hintText: '••••••',
                ),
                onChanged: _onChanged,
              ),
              if (failed) ...[
                const SizedBox(height: 8),
                Text(l10n.pinWrong,
                    style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignedOut()),
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
