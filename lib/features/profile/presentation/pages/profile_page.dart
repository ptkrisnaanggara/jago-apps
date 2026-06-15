import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Profile tab. Personal info comes from the authenticated [AuthUser];
/// security, language & theme settings land here per PRD §3 (P2).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
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
            const _SettingTile(icon: Icons.lock_outline, label: 'Keamanan'),
            const _SettingTile(
                icon: Icons.language_outlined, label: 'Bahasa'),
            const _SettingTile(
                icon: Icons.dark_mode_outlined, label: 'Tampilan'),
            const _SettingTile(
                icon: Icons.help_outline_rounded, label: 'Bantuan'),
            _SettingTile(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              onTap: () => _confirmSignOut(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
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
  final VoidCallback? onTap;

  const _SettingTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap ?? () {},
    );
  }
}
