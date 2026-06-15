import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Placeholder Profile tab. Personal info, security, language & theme
/// settings land here per PRD §3 (P2).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'Shankara Anggara',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'shankaangga@gmail.com',
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
            const _SettingTile(icon: Icons.logout_rounded, label: 'Keluar'),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SettingTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }
}
