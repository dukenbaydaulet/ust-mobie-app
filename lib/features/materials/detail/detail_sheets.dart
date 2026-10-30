import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/typography.dart';
import '../../../core/api_client.dart';
import '../../../core/config.dart';
import '../../auth/auth_controller.dart';
import '../material.dart';
import '../material_detail.dart';
import '../materials_repository.dart';
import '../widgets/material_widgets.dart';

const _green = Color(0xFF16A34A);

// ============================================================
// Ортақ бөліктер
// ============================================================

/// Терезе артындағы фонды бұлыңғырлайды
Widget _blurBackground(Widget child) => BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
  child: child,
);

/// Терезенің ең үлкен ені — дизайндағы терезе ені
const _dialogMaxWidth = 370.0;

/// Терезе каркасы: ақ карточка, бұрышы 24, экран ортасында.
Future<T?> _showCenterDialog<T>(BuildContext context, WidgetBuilder builder) {
  final width = MediaQuery.sizeOf(context).width;
  final side = ((width - _dialogMaxWidth) / 2).clamp(16.0, double.infinity);
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => _blurBackground(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: side, vertical: 16),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: builder(ctx),
      ),
    ),
  );
}

/// Жабу батырмасы: 32×32, фоны #E6EEFF
class _CloseButton extends StatelessWidget {
  const _CloseButton({this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MColors.primarySoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.close, size: 18, color: Color(0xFF424654)),
        ),
      ),
    );
  }
}

/// Материал белгісі: файл белгішесі + атауы (бір жол)
class MaterialChip extends StatelessWidget {
  const MaterialChip({super.key, required this.material, this.subtitle});
  final StudyMaterial material;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: MColors.page,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          FileTypeIcon(type: material.fileType, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppText.tag.copyWith(color: AppText.link),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Көк негізгі батырма (биіктігі 50)
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.height = 50,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: MColors.primary,
          disabledBackgroundColor: MColors.primary.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.action.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Ашық көк батырма (Тіркелу, Жабу)
class _SoftButton extends StatelessWidget {
  const _SoftButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 50,
    this.background = MColors.primarySoft,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double height;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: AppText.link,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppText.action.copyWith(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 1. Қонаққа: «Кабинетке кіру керек»
// ============================================================

Future<void> showLoginRequiredSheet(
  BuildContext context, {
  required StudyMaterial material,
  required String fileSize,
  String purpose = 'Материалды жүктеп алу үшін',
}) {
  // showModalBottomSheet артын бұлыңғырлай алмайды, сондықтан
  // төменнен шығатын парақты өзіміз жасаймыз: фон бұлыңғыр + күңгірт.
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: _LoginRequiredSheet(
          material: material,
          fileSize: fileSize,
          purpose: purpose,
        ),
      ),
    ),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return AnimatedBuilder(
        animation: curved,
        builder: (_, child) => BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6 * curved.value,
            sigmaY: 6 * curved.value,
          ),
          child: child,
        ),
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _LoginRequiredSheet extends ConsumerWidget {
  const _LoginRequiredSheet({
    required this.material,
    required this.fileSize,
    required this.purpose,
  });
  final StudyMaterial material;
  final String fileSize;

  /// «Материалды жүктеп алу үшін», «Материалды сақтау үшін» т.б.
  final String purpose;

  // Түстер дизайн суретінен өлшеп алынды
  static const _handle = Color(0xFFDBDDE7);
  static const _lockBg = Color(0xFFDAE1FF);
  static const _softBg = Color(0xFFDDE9FF);
  static const _badge = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void goLogin() {
      Navigator.of(context).pop();
      // Қонақ режимінен шыққанда router өзі кіру бетіне апарады
      ref.read(guestModeProvider.notifier).exit();
    }

    const bold = TextStyle(color: AppText.ink, fontWeight: FontWeight.w600);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: _handle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _lockBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: AppText.link,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'USTAZ TILEGI • UST.KZ',
                style: AppText.tag.copyWith(
                  color: AppText.muted,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              const _CloseButton(size: 36),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Кабинетке кіру керек', style: AppText.pageTitle),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$purpose '),
                const TextSpan(text: 'кіріңіз', style: bold),
                const TextSpan(text: ' немесе жеке '),
                const TextSpan(text: 'кабинетке тіркеліңіз', style: bold),
                const TextSpan(text: '.'),
              ],
            ),
            style: AppText.hintText.copyWith(fontSize: 15, height: 22 / 15),
          ),
          const SizedBox(height: 24),
          _LoginMaterialCard(
            material: material,
            subtitle: '${material.fileType.toUpperCase()} • $fileSize',
          ),
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'Кіру',
            trailingIcon: Icons.login_rounded,
            height: 46,
            onPressed: goLogin,
          ),
          const SizedBox(height: 12),
          _SoftButton(
            label: 'Тіркелу',
            icon: Icons.person_add_alt_1_outlined,
            height: 46,
            background: _softBg,
            onPressed: goLogin,
          ),
          const SizedBox(height: 22),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 16, color: _badge),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Қазақстан ұстаздарының кәсіби қоғамдастығы',
                    style: AppText.caption,
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

/// «Кабинетке кіру керек» ішіндегі материал карточкасы:
/// ақ шаршыдағы құжат белгішесі + атауы + түрі мен көлемі
class _LoginMaterialCard extends StatelessWidget {
  const _LoginMaterialCard({required this.material, required this.subtitle});
  final StudyMaterial material;
  final String subtitle;

  static const _bg = Color(0xFFEFF4FF);
  static const _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 22,
              color: _blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppText.tag.copyWith(color: _blue, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 2. Тарифтер (жазылым жоқ болса)
// ============================================================

// Түстер дизайн суретінен өлшеп алынды
const _logoBg = Color(0xFFDAE1FF);
const _ustBadge = Color(0xFFFF9800);
const _selectedCard = Color(0xFFF4F6FF);
const _noteBg = Color(0x80FFDCBE);
const _noteIcon = Color(0xFF8B5000);

// Мәтін стильдері — Figma-дағы нақты мәндер
const _interFont = 'Inter';
final _tariffHeading = AppText.sectionTitle.copyWith(letterSpacing: -0.45);
const _tariffLead = TextStyle(
  fontFamily: _interFont,
  fontWeight: FontWeight.w400,
  fontSize: 13,
  height: 17 / 13,
  color: AppText.muted,
);
const _tariffName = TextStyle(
  fontFamily: _interFont,
  fontWeight: FontWeight.w700,
  fontSize: 16,
  height: 24 / 16,
  color: AppText.ink,
);
const _tariffText = TextStyle(
  fontFamily: _interFont,
  fontWeight: FontWeight.w400,
  fontSize: 12,
  height: 16 / 12,
  color: AppText.muted,
);
const _tariffPrice = TextStyle(
  fontFamily: _interFont,
  fontWeight: FontWeight.w700,
  fontSize: 18,
  height: 1,
  color: AppText.link,
);

const _cardShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 3)),
];

/// Тариф сатып алынса — true.
Future<bool> showTariffDialog(BuildContext context) async {
  final result = await _showCenterDialog<bool>(
    context,
    (_) => const _TariffDialog(),
  );
  return result ?? false;
}

class _TariffDialog extends ConsumerStatefulWidget {
  const _TariffDialog();

  @override
  ConsumerState<_TariffDialog> createState() => _TariffDialogState();
}

class _TariffDialogState extends ConsumerState<_TariffDialog> {
  late final Future<List<Tariff>> _tariffs = ref
      .read(materialsRepositoryProvider)
      .tariffs();
  String? _selected;
  bool _buying = false;

  Future<void> _buy(Tariff t) async {
    setState(() => _buying = true);
    final ok = await purchaseTariff(context, ref, t);
    if (!mounted) return;
    setState(() => _buying = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Tariff>>(
      future: _tariffs,
      builder: (context, snap) {
        final list = snap.data;
        if (list == null) {
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final selected = list.firstWhere(
          (t) => t.id == _selected,
          orElse: () => list.firstWhere((t) => t.best, orElse: () => list.last),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Логотип ✕ батырмасынан сәл төмен тұрады
              const Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: _UstLogo(),
                    ),
                  ),
                  Positioned(top: 0, right: 0, child: _CloseButton(size: 36)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Бұл материал жазылушыларға арналған',
                textAlign: TextAlign.center,
                style: _tariffHeading,
              ),
              const SizedBox(height: 8),
              const Text(
                '400 000+ дайын материалға толық қолжетімділік алу үшін жазылым рәсімдеңіз',
                textAlign: TextAlign.center,
                style: _tariffLead,
              ),
              const SizedBox(height: 22),
              for (final t in list) ...[
                // «ЕҢ ТИІМДІ» белгісі карточканың жиегіне шығып тұрады
                if (t.best) const SizedBox(height: 8),
                TariffCard(
                  tariff: t,
                  selected: t.id == selected.id,
                  onTap: () => setState(() => _selected = t.id),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 10),
              BuyButton(
                label:
                    '${selected.title.split(' ').first} тарифті таңдау · ${formatNumber(selected.price)} ₸',
                loading: _buying,
                onPressed: () => _buy(selected),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(AppConfig.termsUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(text: 'Төлем жасау арқылы '),
                      TextSpan(
                        text: 'Қолдану ережелерімен',
                        style: TextStyle(
                          color: AppText.ink,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' келісесіз'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _interFont,
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    height: 20 / 11,
                    color: AppText.muted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Тарифті сатып алады. Сайттағыдай: баланс жетпесе — Kaspi арқылы толтырып,
/// қайта сатып алады. Қате болса — хабар көрсетеді. Сатып алынса — true.
Future<bool> purchaseTariff(
  BuildContext context,
  WidgetRef ref,
  Tariff t,
) async {
  try {
    return await ref.read(materialsRepositoryProvider).buy(t.id);
  } on InsufficientBalanceException catch (e) {
    if (!context.mounted) return false;
    final paid = await _showKaspiDialog(context, ref, price: e.price);
    if (!paid || !context.mounted) return false;
    return purchaseTariff(context, ref, t);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
    return false;
  }
}

/// Kaspi-дегі «Ustaz Tilegi» төлемі: сома пайдаланушы ID-і бойынша
/// сайттағы балансқа түседі (сайттағы oplataPopup.vue сияқты).
Uri kaspiPayUri({required int userId, required int price}) => Uri.parse(
  'https://kaspi.kz/pay/UstazTilegi1'
  '?TranId=1&OrderId=$userId&Amount=${price}00',
);

/// «Балансыңыз жеткіліксіз» → Kaspi арқылы төлеу. Пайдаланушы «Төледім» басса — true.
Future<bool> _showKaspiDialog(
  BuildContext context,
  WidgetRef ref, {
  required int price,
}) async {
  final userId = ref.read(authProvider).value?.id;
  if (userId == null) return false;
  final result = await _showCenterDialog<bool>(
    context,
    (ctx) => _KaspiDialog(userId: userId, price: price),
  );
  return result ?? false;
}

class _KaspiDialog extends StatefulWidget {
  const _KaspiDialog({required this.userId, required this.price});
  final int userId;
  final int price;

  @override
  State<_KaspiDialog> createState() => _KaspiDialogState();
}

class _KaspiDialogState extends State<_KaspiDialog> {
  /// Kaspi ашылды ма — сонда «Төледім» батырмасы шығады
  bool _opened = false;

  Future<void> _pay() async {
    final ok = await launchUrl(
      kaspiPayUri(userId: widget.userId, price: widget.price),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _opened = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaspi-ді ашу мүмкін болмады')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: _CloseButton(size: 36),
          ),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.account_balance_wallet,
                size: 28,
                color: Color(0xFFF14635),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Балансыңыз жеткіліксіз',
            textAlign: TextAlign.center,
            style: _tariffHeading,
          ),
          const SizedBox(height: 8),
          Text(
            _opened
                ? 'Kaspi-де төлегеннен кейін сома балансыңызға бірден түседі. '
                      'Төледіңіз бе? Тарифті қосамыз.'
                : 'Тарифті қосу үшін балансыңызды Kaspi арқылы '
                      '${formatNumber(widget.price)} ₸-ге толтырыңыз. '
                      'Сома балансқа бірден түседі.',
            textAlign: TextAlign.center,
            style: _tariffLead,
          ),
          const SizedBox(height: 6),
          Text(
            'Сіздің ID: ${widget.userId}',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _pay,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF14635),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Kaspi арқылы төлеу · ${formatNumber(widget.price)} ₸',
                style: AppText.action.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (_opened) ...[
            const SizedBox(height: 10),
            _SoftButton(
              label: 'Төледім — тарифті қосу',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ],
      ),
    );
  }
}

/// Дөңгелек фондағы логотип + қызғылт сары «UST.KZ» белгісі
class _UstLogo extends StatelessWidget {
  const _UstLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4,
            top: 0,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _logoBg,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset('assets/images/logo.svg', height: 22),
            ),
          ),
          Positioned(
            left: 36,
            top: 11,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: const ShapeDecoration(
                color: _ustBadge,
                shape: StadiumBorder(),
              ),
              child: Text(
                'UST.KZ',
                style: AppText.tag.copyWith(
                  color: AppText.chipStrong.color,
                  fontSize: 9,
                  height: 12 / 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TariffCard extends StatelessWidget {
  const TariffCard({
    super.key,
    required this.tariff,
    required this.selected,
    required this.onTap,
    this.inkPrice = false,
  });
  final Tariff tariff;
  final bool selected;

  /// Таңдалмаған картаның бағасы көк емес, қара болады.
  final bool inkPrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = tariff;
    final radius = BorderRadius.circular(16);
    final card = DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: _cardShadow),
      child: Material(
        color: selected ? _selectedCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
              ? const BorderSide(color: MColors.primary, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, t.best ? 20 : 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: selected
                                ? _tariffName.copyWith(
                                    fontSize: 18,
                                    height: 24 / 18,
                                    color: AppText.link,
                                  )
                                : _tariffName,
                          ),
                          Text(
                            t.subtitle,
                            style: selected
                                ? _tariffText.copyWith(color: AppText.slate)
                                : _tariffText,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Radio(selected: selected),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${formatNumber(t.price)} ₸',
                      style: selected
                          ? _tariffPrice.copyWith(height: 24 / 18)
                          : inkPrice
                          ? _tariffPrice.copyWith(color: AppText.ink)
                          : _tariffPrice,
                    ),
                    const SizedBox(width: 4),
                    Text(t.period, style: _tariffText),
                    if (t.oldPrice != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '${formatNumber(t.oldPrice!)} ₸',
                        style: _tariffText.copyWith(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppText.muted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (t.note != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _noteBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: _noteIcon,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Ескерту: ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: t.note),
                              ],
                            ),
                            style: _tariffText.copyWith(
                              color: AppText.chipStrong.color,
                              height: 15 / 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!t.best) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          left: 16,
          top: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: const ShapeDecoration(
              color: AppText.link,
              shape: StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Symbols.local_fire_department,
                  size: 12,
                  weight: 600,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'ЕҢ ТИІМДІ',
                  style: AppText.tag.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    height: 12 / 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Таңдалса — көк дөңгелек, ортасында ақ нүкте; әйтпесе — ашық көк дөңгелек
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppText.link : MColors.primarySoft,
      ),
      child: selected
          ? Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

/// «Жылдық тарифті таңдау · 4 990 ₸ →» — қою көк, көлеңкелі
class BuyButton extends StatelessWidget {
  const BuyButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33004BC0),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppText.link,
          disabledBackgroundColor: AppText.link.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.action.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}

// ============================================================
// 3. Шағым жазу → «Шағымыңыз қабылданды»
// ============================================================

const _complaintTop = Color(0xFFF1F2F7);
const _flagRed = Color(0xFFBA1A1A);
const _flagBg = Color(0x99FFDAD6);

/// «Шағым жазу», «Шағымыңыз қабылданды» — Arimo 600 22/27.5
const _complaintTitle = TextStyle(
  fontFamily: 'Arimo',
  fontWeight: FontWeight.w600,
  fontSize: 22,
  height: 27.5 / 22,
  color: AppText.ink,
);

Future<void> showComplaintDialog(
  BuildContext context, {
  required StudyMaterial material,
}) {
  return _showCenterDialog<void>(
    context,
    (_) => _ComplaintDialog(material: material),
  );
}

/// Қызыл жалауша, 40×40 дөңгелекте
class _FlagIcon extends StatelessWidget {
  const _FlagIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: _flagBg, shape: BoxShape.circle),
      child: const Icon(Symbols.flag, size: 20, fill: 1, color: _flagRed),
    );
  }
}

/// Ішкі көлеңке (CSS: box-shadow: 0 2px 4px #00000026 inset)
class _InnerShadow extends CustomPainter {
  const _InnerShadow({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    // Ішкі пішіннің сыртын бояймыз — бұлыңғырланған шеті ішке түседі
    final hole = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rrect.outerRect.inflate(20))
      ..addRRect(rrect.shift(const Offset(0, 2)));
    canvas.drawPath(
      hole,
      Paint()
        ..color = const Color(0x26000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InnerShadow old) => old.radius != radius;
}

/// Материал атауы: көк құжат белгішесі + атауы (бір жол)
class _ComplaintMaterial extends StatelessWidget {
  const _ComplaintMaterial({required this.material});
  final StudyMaterial material;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Symbols.description, size: 18, color: AppText.link),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              material.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 16 / 12,
                color: AppText.slate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintDialog extends ConsumerStatefulWidget {
  const _ComplaintDialog({required this.material});
  final StudyMaterial material;

  @override
  ConsumerState<_ComplaintDialog> createState() => _ComplaintDialogState();
}

class _ComplaintDialogState extends ConsumerState<_ComplaintDialog> {
  static const _min = 30;
  static const _max = 300;
  final _text = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await ref
        .read(materialsRepositoryProvider)
        .report(widget.material.id, _text.text.trim());
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: _sent ? _success() : _form());
  }

  Widget _form() {
    final length = _text.text.trim().length;
    final enough = length >= _min;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Жоғарғы сұр бөлік: тақырып, материал, мәтін өрісі
        Container(
          color: _complaintTop,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  _FlagIcon(),
                  SizedBox(width: 12),
                  Expanded(child: Text('Шағым жазу', style: _complaintTitle)),
                  _CloseButton(),
                ],
              ),
              const SizedBox(height: 16),
              _ComplaintMaterial(material: widget.material),
              const SizedBox(height: 14),
              CustomPaint(
                foregroundPainter: const _InnerShadow(radius: 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _text,
                        minLines: 8,
                        maxLines: 8,
                        maxLength: _max,
                        style: AppText.input.copyWith(letterSpacing: 0),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Материалдағы қатені немесе мәселені сипаттаңыз...',
                          hintStyle: AppText.placeholder.copyWith(
                            height: 20 / 14,
                          ),
                        ).copyWith(counterText: ''),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: enough ? _green : AppText.muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$_min әріптен көп болу керек',
                              style: AppText.caption.copyWith(
                                color: enough ? _green : AppText.muted,
                              ),
                            ),
                          ),
                          Text(
                            '$length / $_max',
                            style: AppText.chipStrong.copyWith(
                              color: AppText.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Төменгі ақ бөлік: батырма
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _PrimaryButton(
                label: 'Шағымды жіберу',
                icon: Symbols.send,
                height: 46,
                loading: _sending,
                onPressed: enough ? _send : null,
              ),
              const SizedBox(height: 10),
              Text(
                'Жалған шағымдар үшін аккаунт белсенділігі шектелуі мүмкін',
                style: AppText.caption.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _success() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: _FlagIcon()),
          const SizedBox(height: 16),
          const Text(
            'Шағымыңыз қабылданды',
            textAlign: TextAlign.center,
            style: _complaintTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'Материалды жақын арада тексереміз. Платформаның сапасын жақсартуға көмектескеніңізге рақмет!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 16 / 12,
              color: AppText.slate,
            ),
          ),
          const SizedBox(height: 20),
          _ComplaintMaterial(material: widget.material),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: MColors.primarySoft,
                foregroundColor: AppText.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Жабу',
                style: AppText.action.copyWith(
                  color: AppText.ink,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 4. Бағалау → «Үлкен рақмет, Ұстаз!»
// ============================================================

// Түстер дизайн суретінен өлшеп алынды
const _starEmpty = Color(0xFFD0D7E7);
const _starFull = Color(0xFFFF9800);
const _waBg = Color(0xFFECFDF5);
const _waBorder = Color(0xFFBDF6DC);
const _waText = Color(0xFF065F46);
const _waIcon = Color(0xFF059669);
const _chipBg = Color(0xFFEFF4FF);
const _docBlue = Color(0xFF2563EB);

/// Бағалау терезесінің мәтін стильдері
const _rateTitle = TextStyle(
  fontFamily: 'Arimo',
  fontWeight: FontWeight.w600,
  fontSize: 18,
  height: 24 / 18,
  color: AppText.ink,
);
const _rateText = TextStyle(
  fontFamily: _interFont,
  fontWeight: FontWeight.w400,
  fontSize: 13,
  height: 17 / 13,
  color: AppText.muted,
);
const _rateLink = TextStyle(
  fontFamily: _interFont,
  fontWeight: FontWeight.w600,
  fontSize: 13,
  height: 18 / 13,
  color: AppText.muted,
);

Future<void> showRatingDialog(
  BuildContext context, {
  required StudyMaterial material,
  required String fileSize,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = ((width - _dialogMaxWidth) / 2).clamp(16.0, double.infinity);
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => _blurBackground(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: side, vertical: 16),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _RatingDialog(material: material),
              ),
            ),
            // Терезенің астында, күңгірт фонның үстінде
            const SizedBox(height: 14),
            Text(
              'Ustaz Tilegi · Республикалық ғылыми – әдістемелік орталығы',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                color: const Color(0xFFEFF4FF),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// «WhatsApp-пен бөлісу» — материал сілтемесін WhatsApp арқылы жіберу
class _WhatsAppShareButton extends StatelessWidget {
  const _WhatsAppShareButton({required this.material});
  final StudyMaterial material;

  Future<void> _share() {
    final text = '${material.title}\nhttps://ust.kz/word/${material.id}';
    return launchUrl(
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: TextButton(
        onPressed: _share,
        style: TextButton.styleFrom(
          backgroundColor: _waBg,
          foregroundColor: _waText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _waBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _WhatsAppLogo(size: 16),
            const SizedBox(width: 8),
            Text(
              'WhatsApp-пен бөлісу',
              style: AppText.action.copyWith(color: _waText),
            ),
          ],
        ),
      ),
    );
  }
}

/// WhatsApp логотипі: жасыл толтырылған көпіршік, ортасында ақ телефон
class _WhatsAppLogo extends StatelessWidget {
  const _WhatsAppLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _BubblePainter(color: _waIcon),
        child: Center(
          child: Icon(
            Symbols.call,
            size: size * 0.56,
            fill: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = size.width * 0.46;
    final c = Offset(size.width * 0.52, size.height * 0.48);
    canvas.drawCircle(c, r, paint);
    // Төменгі сол жақтағы «құйрық»
    final tail = Path()
      ..moveTo(size.width * 0.02, size.height)
      ..lineTo(size.width * 0.14, size.height * 0.64)
      ..lineTo(size.width * 0.38, size.height * 0.88)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}

/// Көлеңкелі көк батырма: «Жіберу →», «Жабу»
class _ShadowButton extends StatelessWidget {
  const _ShadowButton({
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x401E63E9),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: MColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppText.action.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(trailingIcon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Тісті белгі (seal), ортасында ақ бас бармақ — «Үлкен рақмет» белгішесі
class _ThanksBadge extends StatelessWidget {
  const _ThanksBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE7EEFF),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: CustomPaint(
          painter: const _SealPainter(color: MColors.primary),
          child: const Center(
            child: Icon(
              Symbols.thumb_up,
              size: 18,
              fill: 1,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// 8 тісті дөңгелек пішін
class _SealPainter extends CustomPainter {
  const _SealPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()..color = color;
    canvas.drawCircle(c, r * 0.8, paint);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawCircle(
        c + Offset(cos(a), sin(a)) * (r * 0.72),
        r * 0.28,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SealPainter old) => old.color != color;
}

class _RatingDialog extends ConsumerStatefulWidget {
  const _RatingDialog({required this.material});
  final StudyMaterial material;

  @override
  ConsumerState<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<_RatingDialog> {
  final _comment = TextEditingController();
  int _stars = 0;
  bool _sending = false;
  bool _sent = false;

  static const _labels = [
    '',
    'Нашар',
    'Орташадан төмен',
    'Орташа',
    'Жақсы',
    'Өте жақсы!',
  ];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await ref
        .read(materialsRepositoryProvider)
        .rate(widget.material.id, _stars, _comment.text.trim());
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _sent ? _thanks() : _form(),
      ),
    );
  }

  List<Widget> _form() => [
    // «✓ Материал жүктеліп алынды!» ортада, ✕ оң жақта
    Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
          decoration: const ShapeDecoration(
            color: MColors.primarySoft,
            shape: StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Symbols.check_circle,
                size: 18,
                fill: 1,
                color: AppText.link,
              ),
              const SizedBox(width: 6),
              Text(
                'Материал жүктеліп алынды!',
                style: AppText.chip.copyWith(
                  color: AppText.link,
                  fontSize: 13,
                  height: 16 / 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Align(
          alignment: Alignment.centerRight,
          child: _CloseButton(size: 36),
        ),
      ],
    ),
    const SizedBox(height: 10),
    _RatingMaterial(material: widget.material),
    const SizedBox(height: 16),
    const Text(
      'Материал ұнады ма?',
      textAlign: TextAlign.center,
      style: _rateTitle,
    ),
    const SizedBox(height: 2),
    const Text(
      'Бағалаңыз және өз пікіріңізді қалдырыңыз',
      textAlign: TextAlign.center,
      style: _rateText,
    ),
    const SizedBox(height: 14),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => setState(() => _stars = i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(
                Symbols.star_rounded,
                size: 34,
                weight: 300,
                fill: i <= _stars ? 1 : 0,
                color: i <= _stars ? _starFull : _starEmpty,
              ),
            ),
          ),
      ],
    ),
    const SizedBox(height: 14),
    Text(
      _stars == 0
          ? 'Бағалау үшін жұлдызды басыңыз'
          : '${_labels[_stars]} ($_stars/5)',
      textAlign: TextAlign.center,
      style: _stars == 0 ? _rateText : _rateLink.copyWith(color: _noteIcon),
    ),
    if (_stars > 0) ...[
      const SizedBox(height: 14),
      _CommentField(controller: _comment),
      const SizedBox(height: 16),
      _ShadowButton(
        label: 'Жіберу',
        trailingIcon: Icons.arrow_forward,
        loading: _sending,
        onPressed: _send,
      ),
      const SizedBox(height: 12),
    ] else
      const SizedBox(height: 24),
    _WhatsAppShareButton(material: widget.material),
    const SizedBox(height: 18),
    Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            _stars == 0 ? 'Кері қайту' : 'Кейінірек',
            style: _rateLink,
          ),
        ),
      ),
    ),
  ];

  List<Widget> _thanks() => [
    Stack(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Center(child: _ThanksBadge()),
        ),
        const Positioned(top: 0, right: 0, child: _CloseButton(size: 36)),
      ],
    ),
    const SizedBox(height: 20),
    const Text(
      'Үлкен рақмет, Ұстаз!',
      textAlign: TextAlign.center,
      style: _rateTitle,
    ),
    const SizedBox(height: 4),
    const Text(
      'Сіздің пікіріңіз білім сапасын арттыруға және әріптестерге дұрыс таңдау жасауға септігін тигізеді!',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: _interFont,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 16 / 12,
        color: AppText.muted,
      ),
    ),
    const SizedBox(height: 16),
    // «Жабу» толық енде емес — ортада, екі жағында 44 dp бос орын
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: _ShadowButton(
        label: 'Жабу',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    const SizedBox(height: 28),
    _WhatsAppShareButton(material: widget.material),
    const SizedBox(height: 4),
  ];
}

/// [DOCX] Атауы  ✓ — бағалау терезесіндегі материал жолы
class _RatingMaterial extends StatelessWidget {
  const _RatingMaterial({required this.material});
  final StudyMaterial material;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              material.fileType.toUpperCase(),
              style: AppText.tag.copyWith(
                color: _docBlue,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              material.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 16 / 12,
                color: AppText.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Symbols.verified, size: 18, color: AppText.link),
        ],
      ),
    );
  }
}

/// Пікір жазатын өріс: ашық көк фон, ішкі көлеңке
class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const _InnerShadow(radius: 12),
      child: Container(
        height: 112,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: _chipBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          maxLength: 500,
          textAlignVertical: TextAlignVertical.top,
          style: AppText.input.copyWith(fontSize: 13, letterSpacing: 0),
          decoration: InputDecoration.collapsed(
            hintText: 'Пікіріңізді жазыңыз (міндетті емес)...',
            hintStyle: _rateText,
          ).copyWith(counterText: ''),
        ),
      ),
    );
  }
}
