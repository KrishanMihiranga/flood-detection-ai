import 'package:flutter/material.dart';

import '../../core/auth/auth_session_repository.dart';
import '../../core/demo/demo_credentials.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators/credentials_validator.dart';
import '../../widgets/app_labeled_text_field.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_round_icon_button.dart';
import '../dashboard/dashboard_shell.dart';
import 'otp_verification_screen.dart';

/// Reference-style login / sign-up: no tabs — footer swaps modes. No social logins.
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _email = TextEditingController(text: DemoCredentials.email);
  final _password = TextEditingController(text: DemoCredentials.password);
  final _confirmPassword =
      TextEditingController(text: DemoCredentials.password);

  bool _isSignUp = false;

  bool _rememberMe = false;
  bool _obscurePassword = false;
  bool _obscureConfirm = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _typing() {
    if (_emailError != null ||
        _passwordError != null ||
        _confirmError != null) {
      setState(() {
        _emailError = null;
        _passwordError = null;
        _confirmError = null;
      });
    }
  }

  void _toggleSignUp(bool value) {
    if (_isSignUp == value) return;
    setState(() {
      _isSignUp = value;
      if (value) {
        _confirmPassword.text = DemoCredentials.password;
      }
      _confirmError = null;
      _passwordError = null;
      _emailError = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final emailErr = CredentialsValidator.email(_email.text);
    final passErr = _isSignUp
        ? CredentialsValidator.passwordSignUp(_password.text)
        : CredentialsValidator.passwordSignIn(_password.text);
    final confirmErr = _isSignUp
        ? CredentialsValidator.confirmPassword(
            password: _password.text,
            confirm: _confirmPassword.text,
          )
        : null;

    if (emailErr != null || passErr != null || confirmErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passErr;
        _confirmError = confirmErr;
      });
      return;
    }

    final email = _email.text.trim();
    if (_isSignUp) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => OtpVerificationScreen(
            fullEmail: email,
            otpLength: OtpVerificationScreen.defaultOtpDigits,
          ),
        ),
      );
      return;
    }

    await AuthSessionRepository.persistSignedInEmail(email);
    if (!mounted) return;
    DashboardShell.openReplaceAll(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final linkStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                const SizedBox(height: 24),
                Text(
                  'Welcome to Flood Guard AI',
                  style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        fontSize: 28,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Community-powered flood alerts — stay informed before the water rises.',
                  style: textTheme.bodyLarge?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 36),
                AppLabeledTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'Enter your Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  errorText: _emailError,
                  onChanged: (_) => _typing(),
                ),
                const SizedBox(height: 22),
                AppLabeledTextField(
                  label: 'Password',
                  controller: _password,
                  hint: _isSignUp ? 'Create Password' : 'Enter your Password',
                  obscureText: _obscurePassword,
                  textInputAction:
                      _isSignUp ? TextInputAction.next : TextInputAction.done,
                  autofillHints: [
                    _isSignUp
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  errorText: _passwordError,
                  onChanged: (_) => _typing(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 22),
                  AppLabeledTextField(
                    label: 'Re-enter password',
                    controller: _confirmPassword,
                    hint: 'Re-enter Password',
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: _confirmError,
                    onChanged: (_) => _typing(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: _isSignUp ? 26 : 12),
                if (!_isSignUp) ...[
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(
                            color: AppColors.textSecondary,
                            width: 1.5,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          fillColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.ctaBackground;
                            }
                            return Colors.transparent;
                          }),
                          checkColor: Colors.white,
                          onChanged: (v) {
                            setState(() => _rememberMe = v ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _rememberMe = !_rememberMe);
                          },
                          child: Text(
                            'Remember me',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ctaBackground,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: linkStyle?.copyWith(
                            decoration: TextDecoration.none,
                          ),
                        ),
                        onPressed: () {/* Forgot password → Firebase later */},
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ] else ...[
                  const SizedBox(height: 6),
                ],
                AppPrimaryButton(
                  label: _isSignUp ? 'Sign up' : 'Login',
                  height: 56,
                  borderRadius: 14,
                  backgroundColor: AppColors.ctaBackground,
                  foregroundColor: AppColors.ctaForeground,
                  onPressed: _submit,
                ),
                const SizedBox(height: 28),
                _AuthFooter(
                  isSignUp: _isSignUp,
                  linkStyle: linkStyle,
                  onLinkTap: () => _toggleSignUp(!_isSignUp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter({
    required this.isSignUp,
    required this.linkStyle,
    required this.onLinkTap,
  });

  final bool isSignUp;
  final TextStyle? linkStyle;
  final VoidCallback onLinkTap;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          color: AppColors.textSecondary,
        );

    final lead =
        isSignUp ? 'Already have an account? ' : "Don't have an account? ";

    final action = isSignUp ? 'Log in' : 'Sign up';

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      children: [
        Text(lead, style: base),
        GestureDetector(
          onTap: onLinkTap,
          child: Text(
            action,
            style: linkStyle?.copyWith(
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}
