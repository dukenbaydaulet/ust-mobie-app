import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/colors.dart';
import '../../core/api_client.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';
import 'widgets/auth_widgets.dart';

/// Құпия сөзді қалпына келтіру: нөмірге жаңа құпия сөз жіберіп, сонымен кіру.
/// Navigator.pop(true) — пайдаланушы нөмірді өңдегісі келеді.
class ResetPasswordSheet extends ConsumerStatefulWidget {
  const ResetPasswordSheet({
    super.key,
    required this.phone,
    required this.displayPhone,
  });

  /// Backend форматы: +7(775) 489-12-34
  final String phone;

  /// Экрандағы формат: +7 (775) 489 - 12 - 34
  final String displayPhone;

  @override
  ConsumerState<ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

/// Дизайнды тексеру режимі: SMS серверге жіберілмейді, таймер 10 секунд.
/// flutter run --dart-define=FAKE_SMS=true
/// Тек debug жинағында жұмыс істейді.
const _fakeSms = kDebugMode && bool.fromEnvironment('FAKE_SMS');

class _ResetPasswordSheetState extends ConsumerState<ResetPasswordSheet> {
  static const _resendSeconds = _fakeSms ? 10 : 60;

  late final _phone = TextEditingController(text: widget.displayPhone);
  final _password = TextEditingController();
  Timer? _timer;

  bool _sent = false;
  bool _sending = false;
  bool _loggingIn = false;
  int _secondsLeft = 0;
  String? _sendError;
  String? _passwordError;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final ok = _fakeSms
          ? await Future.delayed(const Duration(milliseconds: 800), () => true)
          : await ref
                .read(authRepositoryProvider)
                .sendPasswordSms(widget.phone);
      if (!mounted) return;
      if (!ok) {
        setState(() => _sendError = 'Бұл нөмір жүйеде тіркелмеген');
        return;
      }
      setState(() => _sent = true);
      _startTimer();
    } catch (e) {
      if (mounted) setState(() => _sendError = errorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _login() async {
    if (_password.text.isEmpty) {
      setState(() => _passwordError = 'Құпия сөзді енгізіңіз');
      return;
    }
    setState(() {
      _loggingIn = true;
      _passwordError = null;
    });
    try {
      await ref.read(authProvider.notifier).login(widget.phone, _password.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(
          () => _passwordError = isUnauthorized(e)
              ? 'Құпия сөз қате. Қайта теріп көріңіз'
              : errorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Экранның дәл ортасындағы попап (пернетақта ашылса, Dialog өзі жоғары көтеріледі)
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: DecoratedBox(
        // Көлеңке сыртта болуы үшін бөлек қабатта
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 8),
              blurRadius: 10,
              spreadRadius: -6,
            ),
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 20),
              blurRadius: 25,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF004BC0),
                          Color(0xFF1E63E9),
                          Color(0xFFFF9800),
                        ],
                        stops: [0, 0.5, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      size: 16,
                                      color: Color(0xFF004BC0),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Артқа',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 18 / 14,
                                        letterSpacing: 0,
                                        color: Color(0xFF004BC0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Material(
                              color: const Color(0xFFE6EEFF),
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                customBorder: const CircleBorder(),
                                child: const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Color(0xFF424654),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDAE1FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset,
                              color: Color(0xFF004BC0),
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Құпия сөзді қалпына келтіру',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _sent ? 'Код көрсетілген телефон нөміріне жіберілді' : 'Сіздің нөміріңізге WhatsApp немесе СМС арқылы жаңа құпия сөз жібереміз',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...(_sent ? _sentStep() : _confirmStep()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _confirmStep() => [
    const FieldLabel('Телефон нөмірі'),
    AuthField(
      controller: _phone,
      icon: Icons.account_circle_outlined,
      enabled: false,
      bold: true,
      tone: FieldTone.success,
      trailing: EditChip(onTap: () => Navigator.of(context).pop(true)),
    ),
    if (_sendError != null)
      StatusLine(
        icon: Icons.priority_high,
        text: _sendError!,
        color: AppColors.error,
      ),
    const SizedBox(height: 16),
    PrimaryButton(
      label: 'Растап, СМС жіберу',
      icon: Icons.arrow_forward,
      loading: _sending,
      loadingLabel: 'Жіберілуде...',
      onPressed: _send,
    ),
  ];

  List<Widget> _sentStep() {
    final waiting = _secondsLeft > 0;
    return [
      waiting
          ? _Banner(
              color: const Color(0xFF23863C),
              background: const Color(0xFFECFEF6),
              icon: Icons.check_circle,
              title: 'Сізге СМС арқылы жаңа құпия сөз жіберілді',
              subtitle: widget.displayPhone,
              subtitleFontSize: 16,
              subtitleHeight: 18 / 16,
              subtitleLetterSpacing: 0.35,
            )
          : const _Banner(
              color: Color(0xFF864927),
              background: Color(0xFFFFFBEB),
              icon: Icons.check_circle,
              title: 'SMS келмеді ме?',
              subtitle: 'Төмендегі түйме арқылы жаңа құпия сөз сұраңыз',
              subtitleFontSize: 12,
              subtitleHeight: 1,
            ),
      const SizedBox(height: 16),
      const FieldLabel('Құпия сөз:'),
      AuthPasswordField(
        controller: _password,
        error: _passwordError != null,
        enabled: !_loggingIn,
        autofocus: true,
        onChanged: (_) => setState(() => _passwordError = null),
        onSubmitted: (_) => _login(),
      ),
      if (_passwordError != null)
        StatusLine(
          icon: Icons.priority_high,
          text: _passwordError!,
          color: AppColors.error,
        ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Кіру',
        icon: Icons.login,
        loading: _loggingIn,
        loadingLabel: 'Кіру...',
        onPressed: _login,
      ),
      const SizedBox(height: 12),
      if (_sendError != null) ...[
        StatusLine(
          icon: Icons.priority_high,
          text: _sendError!,
          color: AppColors.error,
        ),
        const SizedBox(height: 8),
      ],
      Material(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: waiting || _sending ? null : _send,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_sending)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1E63E9),
                        ),
                      )
                    else
                      Icon(
                        Icons.refresh,
                        size: 16,
                        color: waiting
                            ? const Color(0xFF64748B)
                            : const Color(0xFF1E63E9),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      'SMS-ті қайта жіберу',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: waiting ? 12 : 16,
                        fontWeight: waiting ? FontWeight.w400 : FontWeight.w600,
                        height: 1,
                        letterSpacing: 0,
                        color: waiting
                            ? const Color(0xFF64748B)
                            : const Color(0xFF1E63E9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                waiting
                    ? Text(
                        _formatTime(_secondsLeft),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 18 / 24,
                          letterSpacing: 0.35,
                          color: Color(0xFF004BC0),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      )
                    : const Text(
                        'Түймені басып, жаңа код алыңыз',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1,
                          letterSpacing: 0.35,
                          color: Color(0xFF64748B),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  static String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')} : ${(s % 60).toString().padLeft(2, '0')}';
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.background,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.subtitleFontSize,
    required this.subtitleHeight,
    this.subtitleLetterSpacing = 0,
  });

  final Color color;
  final Color background;
  final IconData icon;
  final String title;
  final String subtitle;
  final double subtitleFontSize;
  final double subtitleHeight;
  final double subtitleLetterSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 0,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w400,
                    height: subtitleHeight,
                    letterSpacing: subtitleLetterSpacing,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
