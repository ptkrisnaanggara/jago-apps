import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_codeController.text.trim().length == 6) {
      context.read<AuthBloc>().add(AuthOtpSubmitted(_codeController.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status || prev.errorMessage != curr.errorMessage,
          listener: (context, state) {
            if (state.status == AuthStatus.otpSent &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
            // On AuthStatus.authenticated the router redirect navigates Home.
          },
          builder: (context, state) {
            final verifying = state.status == AuthStatus.verifying;
            return ListView(
              padding: const EdgeInsets.all(AppTheme.defaultMargin),
              children: [
                Text(
                  'Verifikasi OTP',
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan 6 digit kode yang dikirim ke '
                  '+62 ${state.pendingPhone ?? ''}.',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: textTheme.headlineSmall?.copyWith(letterSpacing: 12),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(),
                    hintText: '••••••',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Demo: gunakan kode 123456',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: verifying ? null : _submit,
                  child: verifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Verifikasi'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
