import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

/// Numeric OTP / PIN row (4–6 digits). Hidden [TextField] handles keyboard & SMS/email autofill.
class AppOtpPinField extends StatefulWidget {
  const AppOtpPinField({
    super.key,
    required this.length,
    required this.controller,
    this.autofocus = true,
    this.onChanged,
    this.enabled = true,
  }) : assert(length == 4 || length == 6);

  final int length;
  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<AppOtpPinField> createState() => _AppOtpPinFieldState();
}

class _AppOtpPinFieldState extends State<AppOtpPinField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_notify);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_notify);
    _focus.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged?.call(widget.controller.text);
    setState(() {});
  }

  bool _isSlotHighlighted(int boxIndex, List<String> chars) {
    if (!_focus.hasFocus) return false;
    if (chars.length < widget.length) return boxIndex == chars.length;
    return boxIndex == widget.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final chars = widget.controller.text.split('');

    final digitStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          fontSize: 22,
        );

    return SizedBox(
      height: 56,
      child: Stack(
        children: [
        AbsorbPointer(
          absorbing: !widget.enabled,
          child: Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? AppColors.surfaceMuted
                          : AppColors.divider.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSlotHighlighted(i, chars)
                            ? AppColors.ctaBackground
                            : AppColors.divider,
                        width: _isSlotHighlighted(i, chars) ? 1.75 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      i < chars.length ? chars[i] : '',
                      style: digitStyle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned.fill(
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofocus: widget.autofocus,
            autocorrect: false,
            showCursor: false,
            cursorWidth: 0,
            obscureText: false,
            style: TextStyle(
              height: 0.01,
              color: Colors.transparent.withValues(alpha: 0),
            ),
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              OtpDigitsOnlyFormatter(widget.length),
            ],
            decoration: const InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
        ),
        ],
      ),
    );
  }
}

/// Digits-only, fixed max length — supports paste + platform OTP autofill.
class OtpDigitsOnlyFormatter extends TextInputFormatter {
  OtpDigitsOnlyFormatter(this.maxDigits);

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = d.length <= maxDigits ? d : d.substring(0, maxDigits);
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }
}
