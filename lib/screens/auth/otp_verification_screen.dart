import 'package:flutter/material.dart';

import '../../core/auth/auth_session_repository.dart';
import '../../core/demo/demo_credentials.dart';
import '../../core/formatting/email_preview.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators/otp_validator.dart';
import '../../widgets/app_otp_pin_field.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_round_icon_button.dart';
import '../dashboard/dashboard_shell.dart';

/// OTP entry after signup triggers email verification (backend / Firebase later).
///
/// Supports [otpLength] of **4** or **6** (see [defaultOtpDigits]).
class OtpVerificationScreen extends StatefulWidget {
  /// Default OTP digit count across the app.
  static const int defaultOtpDigits = 6;

  const OtpVerificationScreen({
    super.key,
    required this.fullEmail,
    this.otpLength = defaultOtpDigits,
  }) : assert(otpLength == 4 || otpLength == 6);

  /// Used only to show a masked address in UI.
  final String fullEmail;

  /// OTP width — choose **4** or **6** digits.
  final int otpLength;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otp = TextEditingController();

  String? _otpError;

  @override
  void initState() {
    super.initState();
    _otp.text = DemoCredentials.otpForLength(widget.otpLength);
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  void _onOtpChanged(String _) {
    if (_otpError != null) setState(() => _otpError = null);
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();

    final err = OtpValidator.requireComplete(_otp.text, widget.otpLength);
    if (err != null) {
      setState(() => _otpError = err);
      return;
    }

    await AuthSessionRepository.persistSignedInEmail(widget.fullEmail.trim());
    if (!mounted) return;
    DashboardShell.openReplaceAll(context);
  }

  void _resend() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Resend code to ${EmailPreview.maskEmail(widget.fullEmail)} (stub).',
          style: const TextStyle(height: 1.35),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final masked = EmailPreview.maskEmail(widget.fullEmail);
    final linkStyle = textTheme.bodyMedium?.copyWith(
      color: AppColors.ctaBackground,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 8, 24, 28 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppRoundIconButton(
                    tooltip: 'Back',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Enter verification code',
                  style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.55,
                        fontSize: 28,
                        height: 1.15,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a ${widget.otpLength}-digit code to '
                  '$masked via email.',
                  style: textTheme.bodyLarge?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 36),
                AppOtpPinField(
                  length: widget.otpLength,
                  controller: _otp,
                  autofocus: true,
                  onChanged: _onOtpChanged,
                ),
                if (_otpError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _otpError!,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFC13515),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                AppPrimaryButton(
                  label: 'Verify',
                  height: 56,
                  borderRadius: 14,
                  onPressed: _verify,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ctaBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: linkStyle?.copyWith(
                        decoration: TextDecoration.none,
                      ),
                    ),
                    onPressed: _resend,
                    child: const Text("Didn't get a code? Resend"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
