import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/colors.dart';

/// Логотип + "USTAZ TILEGI" + сипаттама
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/images/logo.svg', height: 24),
            const SizedBox(width: 6),
            SvgPicture.asset(
              'assets/images/wordmark.svg',
              width: 105,
              height: 14,
              colorFilter: const ColorFilter.mode(
                Color(0xFF363636),
                BlendMode.srcIn,
              ),
              semanticsLabel: 'USTAZ TILEGI',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Республикалық ғылыми – әдістемелік\nорталығы',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 16 / 14,
            letterSpacing: 0,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }
}

enum FieldTone { normal, filled, disabled, error, success }

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.icon,
    this.hint,
    this.tone = FieldTone.normal,
    this.enabled = true,
    this.obscureText = false,
    this.bold = false,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final FieldTone tone;
  final bool enabled;
  final bool obscureText;
  final bool bold;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (tone) {
      FieldTone.normal => (
        AppColors.field,
        AppColors.fieldBorder,
        AppColors.text,
      ),
      FieldTone.filled => (
        AppColors.fieldFilled,
        AppColors.fieldFilledBorder,
        AppColors.text,
      ),
      FieldTone.disabled => (
        AppColors.fieldDisabled,
        AppColors.fieldDisabled,
        AppColors.text,
      ),
      FieldTone.error => (
        AppColors.errorSoft,
        AppColors.errorBorder,
        AppColors.error,
      ),
      FieldTone.success => (
        AppColors.successSoft,
        AppColors.successBorder,
        AppColors.success,
      ),
    };
    final iconColor = tone == FieldTone.error || tone == FieldTone.success
        ? fg
        : AppColors.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              obscureText: obscureText,
              obscuringCharacter: '*',
              autofocus: autofocus,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              cursorColor: AppColors.primary,
              style: TextStyle(
                fontSize: bold ? 17 : 15,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: fg,
                letterSpacing: obscureText ? 1.5 : 0,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textHint,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Көзшесі бар құпия сөз өрісі. Толтырылғанда көгілдір түске боялады.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    this.error = false,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool error;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final tone = widget.error
        ? FieldTone.error
        : widget.controller.text.isNotEmpty
        ? FieldTone.filled
        : FieldTone.normal;
    return AuthField(
      controller: widget.controller,
      icon: Icons.lock_outline,
      hint: 'Құпия сөз',
      tone: tone,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: _obscure,
      onChanged: (v) {
        setState(() {});
        widget.onChanged?.call(v);
      },
      onSubmitted: widget.onSubmitted,
      trailing: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
        ),
        color: widget.error ? AppColors.error : AppColors.textMuted,
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

/// Өріс астындағы шағын жазу (қате, ескерту, сәтті)
class StatusLine extends StatelessWidget {
  const StatusLine({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: color)),
          ),
        ],
      ),
    );
  }
}

class EditChip extends StatelessWidget {
  const EditChip({super.key, required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: 13, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'Өңдеу',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.loadingItalic = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final bool loadingItalic;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        // Батырма толық еніне созылуы үшін
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?current]),
        child: loading
            ? Container(
                key: const ValueKey('loading'),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primary,
                      ),
                    ),
                    if (loadingLabel != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        loadingLabel!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontStyle: loadingItalic
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : FilledButton(
                key: const ValueKey('idle'),
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 18),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// Ашық көк фонды батырма ("Қонақ режимі")
class SoftButton extends StatelessWidget {
  const SoftButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.primarySoft,
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
