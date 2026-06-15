import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context
          .read<AuthBloc>()
          .add(AuthOtpRequested(phone: _phoneController.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          // Only react to the request→sent transition (so a failed OTP verify,
          // which also lands on otpSent, doesn't re-push the OTP page).
          listenWhen: (prev, curr) =>
              (prev.status == AuthStatus.requestingOtp &&
                  curr.status == AuthStatus.otpSent) ||
              (curr.status == AuthStatus.failure &&
                  prev.status != curr.status),
          listener: (context, state) {
            if (state.status == AuthStatus.otpSent) {
              context.push(AppRouter.otp);
            } else if (state.status == AuthStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            final loading = state.status == AuthStatus.requestingOtp;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.defaultMargin),
                children: [
                  Text(
                    'Masuk ke Jago',
                    style: textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan nomor HP-mu untuk menerima kode OTP.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP',
                      prefixText: '+62 ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.length < 8) return 'Nomor HP tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text('Kirim Kode OTP'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun?'),
                      TextButton(
                        onPressed: () => context.push(AppRouter.signUp),
                        child: const Text('Daftar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
