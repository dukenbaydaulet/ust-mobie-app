import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/typography.dart';
import '../../core/config.dart';
import '../materials/widgets/material_widgets.dart';
import 'widgets/profile_widgets.dart';

/// «Көмек»: байланыс арналары, жиі қойылатын сұрақтар, жұмыс кестесі.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = [
    (
      'Жазылымды (Ustaz Pro) қалай тоқтатуға немесе басқаруға болады?',
      'Жеке кабинеттегі «Жазылымды басқару» бөлімінде тарифті ауыстыруға '
          'немесе мерзімін ұзартуға болады. Жазылым бір реттік төлеммен '
          'алынады: мерзімі біткенде өзі тоқтайды, картадан ақша автоматты '
          'шешілмейді.',
    ),
    (
      'Материалды жүктеп алу неге сәтсіз аяқталды?',
      'Интернет байланысын және телефондағы бос орынды тексеріңіз. Жазылымыңыз '
          'белсенді екеніне көз жеткізіңіз. Мәселе шешілмесе, қолдау қызметіне '
          'жазыңыз.',
    ),
    (
      'Сертификаттар мен дипломдарды қалай басып шығаруға болады?',
      'Сертификаттар ust.kz сайтындағы жеке кабинетте сақталады. Оларды PDF '
          'түрінде жүктеп алып, кез келген принтерде басып шығаруға болады.',
    ),
    (
      'Жүктелген материалдар қайда сақталады?',
      'Жүктелген файл телефонның жадында сақталып, телефондағы құжат ашатын '
          'қосымшамен (мысалы, WPS немесе PDF оқитын қосымша) ашылады. '
          'Жүктелген материалдардың тізімі «Материалдарым» → «Жүктелгендер» '
          'бөлімінде.',
    ),
    (
      'Төлем жасағаннан кейін Pro жазылым бірден қосыла ма?',
      'Иә. Kaspi арқылы төленген сома балансқа бірден түседі, ал тарифті '
          'таңдағанда жазылым сол сәтте қосылады.',
    ),
    (
      'Өз сабақ жоспарыңызды немесе мақалаңызды сайтқа қалай жариялаймын?',
      'ust.kz сайтындағы жеке кабинетке кіріп, «Материал жариялау» бөлімі '
          'арқылы файлыңызды жүктеңіз. Модерациядан кейін материал сайтта '
          'жарияланады.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    void open(String url) =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

    return Scaffold(
      backgroundColor: MColors.page,
      body: Column(
        children: [
          const ProfileTopBar(title: 'Көмек'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                const _SectionTitle(
                  icon: Symbols.forum,
                  title: 'Байланыс арналары',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ContactCard(
                        icon: Symbols.chat,
                        title: 'WhatsApp',
                        subtitle: '+7 (771) 234-55-99',
                        onTap: () => open(AppConfig.supportWhatsApp),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ContactCard(
                        glyph: const _InstagramGlyph(),
                        title: 'Instagram',
                        subtitle: '@ustaz.tilegi',
                        onTap: () => open('https://instagram.com/ustaz.tilegi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ContactCard(
                        icon: Symbols.mail,
                        title: 'Email',
                        subtitle: 'ustaztilegi@gmail.com',
                        underline: true,
                        onTap: () => open('mailto:ustaztilegi@gmail.com'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle(
                  icon: Symbols.quiz,
                  title: 'Жиі қойылатын сұрақтар',
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _faq.length; i++) ...[
                  _FaqItem(
                    question: _faq[i].$1,
                    answer: _faq[i].$2,
                    initiallyOpen: i == 0,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
                WhiteCard(
                  color: PColors.iconBg,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Symbols.schedule,
                            size: 16,
                            color: MColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Жұмыс кестесі',
                            style: PText.rowStrong.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Дүйсенбі — Жұма: 09:00 - 19:00',
                        style: PText.lead,
                      ),
                      const Text(
                        'Сенбі, жексенбі - демалыс',
                        style: PText.lead,
                      ),
                    ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, weight: 600, color: _blue),
        const SizedBox(width: 8),
        Text(title, style: PText.cardTitle.copyWith(fontSize: 17)),
      ],
    );
  }
}

const _blue = Color(0xFF004BC0);

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    this.icon,
    this.glyph,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.underline = false,
  });
  final IconData? icon;

  /// Белгіше орнына дайын виджет (Instagram).
  final Widget? glyph;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3EBFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: glyph ?? Icon(icon, size: 20, color: _blue),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: PText.rowStrong.copyWith(fontSize: 13),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppText.muted,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PText.small.copyWith(
                  decoration: underline ? TextDecoration.underline : null,
                  decorationColor: AppText.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
    this.initiallyOpen = false,
  });
  final String question;
  final String answer;
  final bool initiallyOpen;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: PText.rowStrong.copyWith(
                        fontSize: 13,
                        height: 18 / 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: _blue,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, right: 20),
                        child: Text(widget.answer, style: PText.lead),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Instagram белгісі: дөңгелек бұрышты шаршы, ортасында шеңбер, бұрышта нүкте.
class _InstagramGlyph extends StatelessWidget {
  const _InstagramGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(color: _blue, width: 1.8),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _blue, width: 1.8),
            ),
          ),
          const Positioned(
            top: 2,
            right: 2,
            child: CircleAvatar(radius: 1.1, backgroundColor: _blue),
          ),
        ],
      ),
    );
  }
}
