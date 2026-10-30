import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/typography.dart';
import '../../core/config.dart';
import '../../core/api_client.dart';
import '../auth/auth_controller.dart';
import '../materials/detail/detail_sheets.dart'
    show BuyButton, TariffCard, purchaseTariff;
import '../materials/material_detail.dart';
import '../materials/materials_repository.dart';
import '../materials/widgets/material_widgets.dart';
import 'profile_repository.dart';
import 'widgets/profile_widgets.dart';

final _tariffsProvider = FutureProvider.autoDispose<List<Tariff>>(
  (ref) => ref.read(materialsRepositoryProvider).tariffs(),
);

/// «Жазылым»: жазылым жоқ болса — тарифтер, бар болса — күйі және ауыстыру.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionState();
}

class _SubscriptionState extends ConsumerState<SubscriptionScreen> {
  /// «Жазылымды тоқтату» жолы әзірге жасырын.
  static const _showCancel = false;

  String? _selected;
  bool _buying = false;

  Future<void> _buy(Tariff t) async {
    setState(() => _buying = true);
    final ok = await purchaseTariff(context, ref, t);
    if (!mounted) return;
    setState(() => _buying = false);
    if (ok) {
      ref.invalidate(subscriptionProvider);
      await ref.read(authProvider.notifier).reload();
      if (mounted) showMessage(context, 'Тариф қосылды');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tariffs = ref.watch(_tariffsProvider);
    final sub = ref.watch(subscriptionProvider);
    final list = tariffs.value;
    final loading = list == null || sub.isLoading;
    final error = tariffs.error ?? sub.error;

    Widget body;
    Widget? bottom;
    if (error != null && !loading) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorMessage(error),
                textAlign: TextAlign.center,
                style: PText.lead,
              ),
              TextButton(
                onPressed: () {
                  ref.invalidate(_tariffsProvider);
                  ref.invalidate(subscriptionProvider);
                },
                child: const Text('Қайталау'),
              ),
            ],
          ),
        ),
      );
    } else if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final current = sub.value;
      final selected = list.firstWhere(
        (t) => t.id == (_selected ?? current?.plan),
        orElse: () => list.firstWhere((t) => t.best, orElse: () => list.last),
      );
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Center(child: _BigLogo()),
          const SizedBox(height: 16),
          if (current == null)
            ..._intro()
          else ...[
            _CurrentCard(sub: current),
            const SizedBox(height: 24),
            const Text('Тарифті ауыстыру', style: PText.cardTitle),
            const SizedBox(height: 2),
            const Text(
              'Басқа тарифке ауысу немесе мерзімін ұзарту',
              style: PText.lead,
            ),
          ],
          const SizedBox(height: 16),
          for (final t in list) ...[
            if (t.best) const SizedBox(height: 8),
            TariffCard(
              tariff: t,
              selected: t.id == selected.id,
              inkPrice: true,
              onTap: () => setState(() => _selected = t.id),
            ),
            const SizedBox(height: 14),
          ],
          if (current == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE6EEFF),
                    child: Icon(
                      Symbols.lock,
                      size: 18,
                      weight: 600,
                      color: AppText.slate,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Бір реттік төлем. Автоматты жаңарту жоқ.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 18 / 13,
                            color: AppText.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Тариф мерзімі аяқталған соң картаңыздан ақша '
                          'автоматты түрде шешілмейді.',
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
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8E6DA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Symbols.info,
                    size: 18,
                    fill: 1,
                    color: Color(0xFF8B5000),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ағымдағы жоспарыңыз ауыстырылған соң, жаңа тариф '
                      'ағымдағы мерзім аяқталғаннан кейін басталады.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        height: 18 / 13,
                        color: MColors.orangeText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // «Жазылымды тоқтату» әзірге жасырын
            if (_showCancel) ...[
              const SizedBox(height: 16),
              _ActionRow(
                icon: Symbols.pause_circle,
                title: 'Жазылымды тоқтату',
                subtitle: 'Тоқтатсаңыз мерзім біткенше қолжетімді болады',
                onTap: _cancel,
              ),
            ],
          ],
        ],
      );
      final extend = current != null && selected.id == current.plan;
      bottom = _BottomBar(
        button: BuyButton(
          label: extend
              ? 'Мерзімін ұзарту · ${formatNumber(selected.price)} ₸'
              : '${selected.title.split(' ').first} тарифті таңдау · '
                    '${formatNumber(selected.price)} ₸',
          loading: _buying,
          onPressed: () => _buy(selected),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MColors.page,
      body: Column(
        children: [
          const ProfileTopBar(title: 'Жазылым'),
          Expanded(child: body),
          ?bottom,
        ],
      ),
    );
  }

  List<Widget> _intro() => [
    const SizedBox(height: 8),
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Материалдарды шектеусіз жүктеп алыңыз',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Arimo',
          fontWeight: FontWeight.w600,
          fontSize: 24,
          height: 32 / 24,
          color: AppText.ink,
        ),
      ),
    ),
    const SizedBox(height: 6),
    const Text(
      'Өзіңізге ыңғайлы тарифті таңдаңыз',
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
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Column(
        children: [
          _Feature('400 000+ дайын материал'),
          _Feature('Premium авторлық материалдар'),
          _Feature('Шектеусіз жылдам жүктеу'),
          _Feature('Жүктеген материалдарыңыз сақталады', last: true),
        ],
      ),
    ),
  ];

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Жазылымды тоқтату', style: PText.cardTitle),
        content: const Text(
          'Жазылым тоқтатылса да, төленген мерзім біткенше материалдар '
          'қолжетімді болып қала береді.',
          style: PText.lead,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Бас тарту'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Тоқтату', style: TextStyle(color: PColors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(profileRepositoryProvider).cancelSubscription();
      ref.invalidate(subscriptionProvider);
      if (mounted) showMessage(context, 'Жазылым тоқтатылды');
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    }
  }
}

/// Үлкен логотип + оң жақ жоғарғы бұрышындағы «UST.KZ» белгісі.
class _BigLogo extends StatelessWidget {
  const _BigLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 82,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 14,
            child: Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFDAE1FF),
                shape: BoxShape.circle,
              ),
              // U — көк градиентпен (200°: #1E63E9 → #6398FF)
              child: SvgPicture.asset('assets/images/U_blue.svg', height: 38),
            ),
          ),
          Positioned(
            left: 46,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'UST.KZ',
                style: AppText.tag.copyWith(
                  color: MColors.orangeText,
                  fontSize: 11,
                  height: 14 / 11,
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

class _Feature extends StatelessWidget {
  const _Feature(this.text, {this.last = false});
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFDCE6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.check,
              size: 16,
              weight: 700,
              color: Color(0xFF1E63E9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 20 / 14,
                color: AppText.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Ағымдағы жазылым» карточкасы: мерзімі, қалған күн, прогресс.
class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.sub});
  final Subscription sub;

  static const _blue = Color(0xFF1E63E9);

  @override
  Widget build(BuildContext context) {
    final left = sub.leftShare;
    const muted = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      height: 20 / 14,
      color: AppText.muted,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFFE5ECFF),
        child: Stack(
          children: [
            // Оң жақ төменгі бұрыштағы сәндік дөңгелек
            Positioned(
              right: -50,
              bottom: -60,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFD8E3FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Ағымдағы жазылым', style: muted),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: StadiumBorder(),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Symbols.check_circle,
                              size: 16,
                              fill: 1,
                              color: _blue,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Белсенді',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                height: 18 / 14,
                                color: AppText.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          sub.title,
                          style: AppText.pageTitle.copyWith(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Symbols.workspace_premium,
                        size: 24,
                        fill: 1,
                        color: Color(0xFFFF9800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Symbols.calendar_today,
                        size: 18,
                        color: AppText.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${formatDate(sub.to)} дейін жарамды',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: muted.copyWith(fontSize: 13),
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: StadiumBorder(),
                        ),
                        child: Text(
                          'Қалғаны: ${sub.daysLeft} күн',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            height: 16 / 12,
                            color: Color(0xFF004BC0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Уақыт өткен сайын толады
                  // Жолақтың екі ұшы да дөңгелек
                  Container(
                    height: 10,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: (1 - left).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Басталған: ${formatDate(sub.from)}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            height: 16 / 12,
                            letterSpacing: 0.3,
                            color: AppText.muted,
                          ),
                        ),
                      ),
                      Text(
                        '${(left * 100).round()}% қалды',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 16 / 12,
                          letterSpacing: 0.3,
                          color: Color(0xFF004BC0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Symbols.lock, size: 18, fill: 1, color: _blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Бір реттік төлем — автоматты жаңарту өшірулі. '
                          'Мерзімі біткенде картадан ақша шешілмейді.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 19 / 13,
                            color: AppText.slate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              IconBox(
                icon: icon,
                color: AppText.muted,
                background: PColors.soft,
                circle: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: PText.rowStrong),
                    Text(subtitle, style: PText.small),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppText.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Төменгі ақ жолақ: батырма, ережелер, төлем тәсілдері.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.button});
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final small = PText.small.copyWith(fontSize: 10);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => openLink(AppConfig.termsUrl),
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
              style: small,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final name in ['KASPI QR', 'VISA', 'MASTERCARD'])
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    name,
                    style: AppText.tag.copyWith(
                      color: AppText.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
