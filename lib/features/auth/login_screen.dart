import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/colors.dart';
import '../../core/config.dart';
import '../../core/api_client.dart';
import '../../core/phone.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';
import 'reset_password_sheet.dart';
import 'widgets/auth_widgets.dart';

/// phone — нөмір енгізу, password — тіркелген нөмір, register — жаңа нөмір
enum _Step { phone, password, register }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phoneMask = PhoneMask.formatter();

  _Step _step = _Step.phone;
  bool _busy = false;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;

  String get _backendPhone => PhoneMask.toBackend(_phoneMask.getUnmaskedText());

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _checkPhone() async {
    FocusScope.of(context).unfocus();
    if (!PhoneMask.isValid(_phoneMask.getUnmaskedText())) {
      setState(() => _phoneError = 'Формат дұрыс емес');
      return;
    }
    setState(() {
      _busy = true;
      _phoneError = null;
    });
    try {
      final exists = await ref
          .read(authRepositoryProvider)
          .isRegistered(_backendPhone);
      if (mounted) {
        setState(() => _step = exists ? _Step.password : _Step.register);
      }
    } catch (e) {
      if (mounted) setState(() => _phoneError = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() async {
    if (_password.text.isEmpty) {
      setState(() => _passwordError = 'Құпия сөзді енгізіңіз');
      return;
    }
    setState(() {
      _busy = true;
      _passwordError = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .login(_backendPhone, _password.text);
    } catch (e) {
      if (mounted) {
        setState(
          () => _passwordError = isUnauthorized(e)
              ? 'Құпия сөз қате. Қайта теріп көріңіз'
              : errorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    final password = _password.text;
    final confirm = _confirm.text;
    String? passwordError;
    String? confirmError;
    if (password.isEmpty) {
      passwordError = 'Құпия сөз енгізіңіз';
    } else if (password.length < 4 || password.length > 10) {
      passwordError = 'Құпия сөз 4 пен 10 таңба арасында болуы керек';
    } else if (password != confirm) {
      confirmError = 'Құпия сөздер сәйкес келмейді';
    }
    setState(() {
      _passwordError = passwordError;
      _confirmError = confirmError;
    });
    if (passwordError != null || confirmError != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .register(_backendPhone, password, confirm);
    } catch (e) {
      if (mounted) setState(() => _confirmError = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _editPhone() {
    setState(() {
      _step = _Step.phone;
      _password.clear();
      _confirm.clear();
      _phoneError = null;
      _passwordError = null;
      _confirmError = null;
    });
  }

  Future<void> _openResetSheet() async {
    final edit = await showDialog<bool>(
      context: context,
      builder: (_) =>
          ResetPasswordSheet(phone: _backendPhone, displayPhone: _phone.text),
    );
    if (edit == true) _editPhone();
  }

  Future<void> _showHelp() async {
    // WhatsApp орнатылмаса, wa.me сілтемесі браузерде ашылады
    final ok = await launchUrl(
      Uri.parse(AppConfig.supportWhatsApp),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp-ты ашу мүмкін болмады')),
      );
    }
  }

  FieldTone get _phoneTone {
    if (_phoneError != null) return FieldTone.error;
    if (_busy && _step == _Step.phone) return FieldTone.disabled;
    if (_step == _Step.password) return FieldTone.success;
    return FieldTone.normal;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const _SecureBadge(),
                      const SizedBox(height: 36),
                      const AuthHeader(),
                      const SizedBox(height: 36),
                      AuthCard(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: _cardContent(),
                        ),
                      ),
                      if (_step == _Step.password) ...[
                        const SizedBox(height: 16),
                        _HelpRow(onTap: _showHelp),
                      ],
                      const Spacer(),
                      const SizedBox(height: 24),
                      SoftButton(
                        label: 'Қонақ режимі',
                        onPressed: _busy
                            ? null
                            : () =>
                                  ref.read(guestModeProvider.notifier).enter(),
                      ),
                      const SizedBox(height: 14),
                      const _SslNote(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardContent() {
    final phoneLocked = _step != _Step.phone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Телефон нөмірі'),
        AuthField(
          controller: _phone,
          icon: Icons.account_circle_outlined,
          hint: '+7 (___) ___-__-__',
          keyboardType: TextInputType.phone,
          inputFormatters: [_phoneMask],
          enabled: !phoneLocked && !_busy,
          bold: _phone.text.isNotEmpty,
          tone: _phoneTone,
          onChanged: (_) => setState(() => _phoneError = null),
          onSubmitted: (_) => _checkPhone(),
          trailing: _phoneError != null
              ? const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.error, color: AppColors.error, size: 22),
                )
              : phoneLocked
              ? EditChip(onTap: _busy ? null : _editPhone)
              : null,
        ),
        if (_phoneError != null)
          StatusLine(text: _phoneError!, color: AppColors.error),
        if (_step == _Step.register)
          const StatusLine(
            icon: Icons.info_outline,
            text: 'Нөмір жүйеге жаңадан қосылуда',
            color: AppColors.textMuted,
          ),
        if (_step == _Step.password)
          const StatusLine(
            icon: Icons.check_circle,
            text: 'Нөмір тіркелген, құпия сөзді жазыңыз',
            color: AppColors.success,
          ),

        if (_step == _Step.register) ...[
          const SizedBox(height: 18),
          const FieldLabel('Құпия сөз ойлап табыңыз:'),
          AuthPasswordField(
            controller: _password,
            error: _passwordError != null,
            enabled: !_busy,
            autofocus: true,
            onChanged: (_) => setState(() => _passwordError = null),
          ),
          if (_passwordError != null)
            StatusLine(
              icon: Icons.priority_high,
              text: _passwordError!,
              color: AppColors.error,
            ),
          const SizedBox(height: 18),
          const FieldLabel('Құпия сөзді қайталаңыз:'),
          AuthPasswordField(
            controller: _confirm,
            error: _confirmError != null,
            enabled: !_busy,
            onChanged: (_) => setState(() => _confirmError = null),
            onSubmitted: (_) => _register(),
          ),
          if (_confirmError != null)
            StatusLine(
              icon: Icons.priority_high,
              text: _confirmError!,
              color: AppColors.error,
            ),
        ],

        if (_step == _Step.password) ...[
          const SizedBox(height: 18),
          const FieldLabel('Құпия сөз:'),
          AuthPasswordField(
            controller: _password,
            error: _passwordError != null,
            enabled: !_busy,
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
        ],

        const SizedBox(height: 20),
        switch (_step) {
          _Step.phone => PrimaryButton(
            label: 'Жалғастыру',
            icon: Icons.arrow_forward,
            loading: _busy,
            loadingLabel: 'Тексерілуде',
            onPressed: _checkPhone,
          ),
          _Step.register => PrimaryButton(
            label: 'Тіркелу',
            icon: Icons.arrow_forward,
            loading: _busy,
            loadingLabel: 'Тіркеу жүруде ...',
            loadingItalic: true,
            onPressed: _register,
          ),
          _Step.password => PrimaryButton(
            label: 'Кіру',
            icon: Icons.login,
            loading: _busy,
            loadingLabel: 'Кіру...',
            onPressed: _login,
          ),
        },

        if (_step == _Step.password) ...[
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: _busy ? null : _openResetSheet,
              icon: const Icon(Icons.sms_outlined, size: 16),
              label: const Text('Смс арқылы құпия сөзді еске салу'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.fieldBorder),
          const SizedBox(height: 16),
          if (_step == _Step.phone)
            Text(
              _busy || _phoneError != null
                  ? 'Пайдаланушы аккаунты анықталуда'
                  : 'Сайтқа кіру немесе тіркелу үшін нөміріңізді жазыңыз',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            )
          else
            const Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: '«Тіркелу» батырмасын басу арқылы сіз '),
                  TextSpan(
                    text: 'пайдаланушы келісімінде',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' көрсетілген барлық шарттармен келісесіз'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ],
    );
  }
}

class _SecureBadge extends StatelessWidget {
  const _SecureBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user_outlined, size: 12, color: Color(0xFF004BC0)),
        SizedBox(width: 4),
        Text(
          'Қауіпсіз кіру',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            letterSpacing: 0,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(
              'assets/images/komek.svg',
              width: 14,
              height: 12,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Кіруде қиындық туындады ма?',
              style: TextStyle(fontSize: 13, color: AppColors.text),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Көмек алу'),
          ),
        ],
      ),
    );
  }
}

class _SslNote extends StatelessWidget {
  const _SslNote();

  @override
  Widget build(BuildContext context) {
    // Белгіше мен мәтін бірге ортада тұрады
    return const Center(
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.lock_outline,
                  size: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            TextSpan(
              text:
                  'Мәліметтер 256-биттік SSL арқылы шифрланған және қорғалған',
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          height: 1,
          letterSpacing: 0,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
