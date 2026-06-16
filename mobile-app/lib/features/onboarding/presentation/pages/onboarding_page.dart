import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

const _slideIcons = <IconData>[
  Icons.account_balance_wallet_rounded,
  Icons.savings_rounded,
  Icons.bolt_rounded,
];

String _slideTitle(AppLocalizations l10n, int i) =>
    [l10n.onboardingTitle1, l10n.onboardingTitle2, l10n.onboardingTitle3][i];

String _slideBody(AppLocalizations l10n, int i) =>
    [l10n.onboardingBody1, l10n.onboardingBody2, l10n.onboardingBody3][i];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slideIcons.length - 1;

  void _next() {
    if (_isLast) {
      context.go(AppRouter.signIn);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(AppRouter.signIn),
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _slideIcons.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding:
                        const EdgeInsets.all(AppTheme.defaultMargin),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(_slideIcons[i],
                              size: 64, color: AppColors.primary),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _slideTitle(l10n, i),
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _slideBody(l10n, i),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slideIcons.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: i == _index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.defaultMargin),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_isLast ? l10n.onboardingStart : l10n.actionNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
