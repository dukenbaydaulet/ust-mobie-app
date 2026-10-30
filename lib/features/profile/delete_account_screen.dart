import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/typography.dart';
import '../../core/api_client.dart';
import '../../core/config.dart';
import '../auth/auth_controller.dart';
import 'personal_data_screen.dart' show PasswordField;
import 'profile_repository.dart';
import 'widgets/profile_widgets.dart';

/// «Аккаунтыңызды жоясыз ба?» — салдарлар және растау.
class DeleteAccountScreen extends ConsumerWidget {
  const DeleteAccountScreen({super.key});

  static const _consequences = [
    (
      Symbols.person_remove,
      'Барлық жеке деректеріңіз жойылады',
      'Профиль, мектеп деректері және ұстаз мәртебесі',
    ),
    (
      Symbols.folder_delete,
      'Материалдарыңыз қолжетімсіз болады',
      'Жүктелген сертификаттар, ҚМЖ мен ОМЖ құжаттары',
    ),
    (
      Symbols.cancel,
      'Белсенді жазылым тоқтатылады',
      'Қалған төлем күйіп кетеді, төлем қайтарылмайды',
    ),
    (
      Symbols.receipt_long,
      'Төлем тарихы мен хабарламалар',
      'Чектер мен ресми кіріс архивтері түбегейлі жойылады',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          const ProfileTopBar(title: 'Жеке деректер'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                const Center(
                  child: _WarningIcon(
                    icon: Symbols.no_accounts,
                    badge: Symbols.warning,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Аккаунтыңызды жоясыз ба?',
                  textAlign: TextAlign.center,
                  style: PText.title,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Бұл әрекетті кері қайтару мүмкін емес. Барлық жетістіктеріңіз '
                  'бен материалдарыңыз өшеді.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 20 / 14,
                    color: AppText.muted,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Symbols.error,
                            size: 14,
                            weight: 600,
                            color: PColors.redDeep,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'ЖОЮ КЕЗІНДЕ ОРЫН АЛАТЫН САЛДАРЛАР',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              height: 12 / 10,
                              letterSpacing: 0.5,
                              color: PColors.redDeep,
                            ),
                          ),
                        ],
                      ),
                      for (final c in _consequences) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: PColors.redSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                c.$1,
                                size: 18,
                                weight: 600,
                                color: PColors.redDeep,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.$2, style: _D.title),
                                  const SizedBox(height: 2),
                                  Text(c.$3, style: _D.sub),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _HelpCard(),
                const SizedBox(height: 28),
                BigButton(
                  label: 'Болдырмау (Аккаунтты сақтау)',
                  icon: Icons.arrow_back,
                  color: AppText.link,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _confirm(context),
                    icon: const Icon(
                      Symbols.delete,
                      size: 22,
                      weight: 700,
                      color: PColors.redDeep,
                    ),
                    label: Text(
                      'Аккаунтты жою',
                      style: AppText.action.copyWith(
                        color: PColors.redDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final deleted = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierColor: const Color(0x8064748B),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: const _PasswordDialog(),
      ),
    );
    if (deleted == true && context.mounted) context.go('/account-deleted');
  }
}

/// Қызғылт дөңгелектегі қызыл белгіше + бұрышындағы кіші белгі.
class _WarningIcon extends StatelessWidget {
  const _WarningIcon({required this.icon, required this.badge});
  final IconData icon;
  final IconData badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x66FFDAD6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDAD6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, weight: 700, color: PColors.redDeep),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    spreadRadius: -2,
                    offset: Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    spreadRadius: -1,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(badge, size: 18, weight: 700, color: PColors.redDeep),
            ),
          ),
        ],
      ),
    );
  }
}

// Жою бетінің мәтін стильдері
class _D {
  static const title = TextStyle(
    fontFamily: 'Arimo',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 18 / 14,
    color: AppText.ink,
  );
  static const sub = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 16 / 12,
    color: AppText.muted,
  );
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFDDE9FF),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x1A0054D6),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/images/komek.svg',
              width: 17,
              height: 15,
              colorFilter: const ColorFilter.mode(
                Color(0xFF004BC0),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Көмек қажет пе?',
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 16 / 14,
                    color: AppText.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text('Қолдау тобы жауап беруге дайын', style: _D.sub),
              ],
            ),
          ),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(AppConfig.supportWhatsApp),
              mode: LaunchMode.externalApplication,
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Жазу',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 16 / 12,
                color: Color(0xFF004BC0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Растау үшін құпия сөзді енгізіңіз». Жойылса — true.
class _PasswordDialog extends ConsumerStatefulWidget {
  const _PasswordDialog();

  @override
  ConsumerState<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<_PasswordDialog> {
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    if (_password.text.isEmpty) {
      setState(() => _error = 'Құпия сөзді енгізіңіз');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(profileRepositoryProvider);
    try {
      if (!await repo.checkPassword(user.phone, _password.text)) {
        setState(() {
          _busy = false;
          _error = 'Құпия сөз қате';
        });
        return;
      }
      await repo.deleteAccount(_password.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: _ShieldIcon(),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: PColors.iconBg,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: AppText.slate,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Растау үшін құпия сөзді енгізіңіз',
              textAlign: TextAlign.center,
              style: AppText.sectionTitle.copyWith(
                fontSize: 19,
                height: 24 / 19,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Қауіпсіздік үшін ұстаздық профильді жою алдында жүйедегі құпия '
              'сөзіңізді растаңыз',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 20 / 13,
                color: AppText.muted,
              ),
            ),
            const SizedBox(height: 20),
            PasswordField(
              label: 'Құпия сөз',
              controller: _password,
              onSubmitted: (_) => _delete(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: PText.small.copyWith(color: PColors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            BigButton(
              label: 'Растау және жою',
              icon: Symbols.delete_forever,
              color: PColors.pink,
              loading: _busy,
              onPressed: _delete,
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Бас тарту',
                style: AppText.action.copyWith(
                  color: AppText.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Қызғылт шаршыдағы қалқан + бұрышындағы қызыл нүкте.
class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Symbols.shield_lock,
              size: 22,
              fill: 1,
              color: PColors.redDeep,
            ),
          ),
          // Қызыл сақина: ортасы ақ
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: PColors.redDeep, width: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Аккаунтыңыз жойылды» — кабинеттен шығып, басты бетке оралады.
class AccountDeletedScreen extends ConsumerWidget {
  const AccountDeletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> home() async {
      await ref.read(authProvider.notifier).logout();
      ref.read(guestModeProvider.notifier).enter();
    }

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Center(child: _DoneIcon()),
                  const SizedBox(height: 20),
                  Text(
                    'Аккаунтыңыз жойылды',
                    textAlign: TextAlign.center,
                    style: PText.title.copyWith(fontSize: 25, height: 32 / 25),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Бізбен бірге болғаныңызға рахмет. Кез келген уақытта қайта '
                    'тіркеле аласыз.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      height: 22 / 15,
                      color: AppText.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  WhiteCard(
                    color: PColors.soft,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Symbols.verified_user,
                          size: 20,
                          weight: 600,
                          color: Color(0xFF004BC0),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Деректер қауіпсіздігі',
                                style: PText.rowStrong.copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Жеке ақпараттарыңыз толық тазартылды. Қажет '
                                'болса, 30 күн ішінде көмек көрсету қызметіне '
                                'хабарласа аласыз.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  height: 18 / 13,
                                  color: AppText.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  BigButton(
                    label: 'Басты бетке оралу',
                    trailing: Icons.arrow_forward,
                    color: AppText.link,
                    onPressed: home,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '«USTAZ TILEGI» РЕСПУБЛИКАЛЫҚ\nҒЫЛЫМИ-ӘДІСТЕМЕЛІК ОРТАЛЫҒЫ',
                    textAlign: TextAlign.center,
                    style: AppText.tag.copyWith(
                      color: AppText.muted,
                      fontWeight: FontWeight.w500,
                      height: 14 / 10,
                      letterSpacing: 0.5,
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
}

/// Екі қабат жұмсақ көк дөңгелектегі ✓ белгісі.
class _DoneIcon extends StatelessWidget {
  const _DoneIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5FF),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E9FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.check,
              size: 42,
              weight: 700,
              color: Color(0xFF004BC0),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 8,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: PColors.shadow,
              ),
              child: const Icon(
                Symbols.lock_reset,
                size: 18,
                weight: 600,
                color: AppText.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
