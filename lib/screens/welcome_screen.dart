import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'auth/email_auth_screen.dart';
import '../widgets/app_logo_mark.dart';
import '../widgets/app_primary_button.dart';

/// First screen: brand moment + single clear action (Airbnb-like calm layout).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _onGetStarted(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EmailAuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Column(
                  children: [
                    const AppLogoMark(size: 96),
                    const SizedBox(height: 28),
                    Text(
                      'Flood Guard AI',
                      style: textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Local flood awareness, powered by your community and smart alerts.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              AppPrimaryButton(
                label: 'Get started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => _onGetStarted(context),
              ),
              const SizedBox(height: 12),
              Text(
                'By continuing, you agree to help keep reports accurate and respectful.',
                style: textTheme.bodyMedium?.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
