import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/typography.dart';
import '../auth/auth_controller.dart';
import '../auth/widgets/guest_login_prompt.dart';
import '../materials/material.dart';
import '../materials/materials_repository.dart';
import '../materials/widgets/material_widgets.dart';

// Түстер дизайн суретінен өлшеп алынды
const _pageBg = Color(0xFFF1F2F7);
const _tabsBg = Color(0xFFE6EEFF);
const _infoBg = Color(0xFFEEF2FD);

const _inter = 'Inter';

/// Жүктелген материалдар.
final downloadedMaterialsProvider =
    FutureProvider.autoDispose<List<StudyMaterial>>(
      (ref) => ref.read(materialsRepositoryProvider).downloadedMaterials(),
    );

/// Сақталған материалдар.
final savedMaterialsListProvider =
    FutureProvider.autoDispose<List<StudyMaterial>>(
      (ref) => ref.read(materialsRepositoryProvider).savedMaterials(),
    );

/// Төменгі мәзірден «Материалдарым» ашылған сайын артады — бет күйі
/// (қойынды, сүзгі, сұрыптау) тасталып, әрқашан «Жүктелгендер» ашылады.
final myMaterialsVisitProvider = NotifierProvider<MyMaterialsVisit, int>(
  MyMaterialsVisit.new,
);

class MyMaterialsVisit extends Notifier<int> {
  @override
  int build() => 0;

  void next() => state++;
}

/// «Менің материалдарым»: жүктелгендер мен сақталғандар.
/// Қонаққа — кіру ұсынысы.
class MyMaterialsScreen extends ConsumerWidget {
  const MyMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const LogoHeader(),
            Expanded(
              child: user == null
                  ? const GuestLoginPrompt(
                      icon: Icons.folder_open_outlined,
                      title: 'Материалдарым',
                      text: 'Жүктеген, сақтаған және жариялаған материалдарыңызды көру үшін кабинетке кіріңіз.',
                    )
                  : _MyMaterialsBody(
                      key: ValueKey(ref.watch(myMaterialsVisitProvider)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Tab { downloaded, saved }

enum _Sort { recent, title }

class _MyMaterialsBody extends ConsumerStatefulWidget {
  const _MyMaterialsBody({super.key});

  @override
  ConsumerState<_MyMaterialsBody> createState() => _MyMaterialsBodyState();
}

class _MyMaterialsBodyState extends ConsumerState<_MyMaterialsBody> {
  _Tab _tab = _Tab.downloaded;
  _Sort _sort = _Sort.recent;

  /// Таңдалған пән; null — «Барлық пәндер»
  String? _subject;

  void _selectTab(_Tab tab) => setState(() {
    _tab = tab;
    _subject = null;
  });

  @override
  Widget build(BuildContext context) {
    final downloaded = ref.watch(downloadedMaterialsProvider);
    final saved = ref.watch(savedMaterialsListProvider);
    final current = _tab == _Tab.downloaded ? downloaded : saved;
    final all = current.value ?? const <StudyMaterial>[];

    // Пәндер және әрқайсысындағы материал саны
    final subjects = <String, int>{};
    for (final m in all) {
      final s = m.subject;
      if (s != null) subjects.update(s, (n) => n + 1, ifAbsent: () => 1);
    }
    var items = [
      for (final m in all)
        if (_subject == null || m.subject == _subject) m,
    ];
    if (_sort == _Sort.title) {
      items = [...items]..sort((a, b) => a.title.compareTo(b.title));
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(downloadedMaterialsProvider);
        ref.invalidate(savedMaterialsListProvider);
        await ref.read(
          (_tab == _Tab.downloaded
                  ? downloadedMaterialsProvider
                  : savedMaterialsListProvider)
              .future,
        );
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
        children: [
          const Text('Менің материалдарым', style: AppText.pageTitle),
          const SizedBox(height: 22),
          _Tabs(
            tab: _tab,
            downloaded: downloaded.value?.length,
            saved: saved.value?.length,
            onSelect: _selectTab,
          ),
          const SizedBox(height: 18),
          _SubjectChips(
            subjects: subjects,
            selected: _subject,
            onSelect: (s) => setState(() => _subject = s),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'ФАЙЛДАР ТІЗІМІ',
                style: const TextStyle(
                  fontFamily: _inter,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  height: 14 / 10,
                  letterSpacing: 0.6,
                  color: AppText.muted,
                ),
              ),
              const Spacer(),
              _SortButton(
                sort: _sort,
                recentLabel: _tab == _Tab.downloaded
                    ? 'Жақында жүктелгендер'
                    : 'Жақында сақталғандар',
                onSelect: (s) => setState(() => _sort = s),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...switch (current) {
            AsyncError() => [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Тізімді жүктеу мүмкін болмады',
                  textAlign: TextAlign.center,
                  style: AppText.caption,
                ),
              ),
            ],
            AsyncData() => [
              for (final m in items) ...[
                MaterialCard(
                  material: m,
                  onTap: () => context.push('/material/${m.id}'),
                ),
                const SizedBox(height: 4),
              ],
              if (items.isEmpty && _tab == _Tab.downloaded)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Әзірге жүктелген материал жоқ',
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),
                ),
            ],
            _ => const [
              MaterialCardSkeleton(),
              SizedBox(height: 4),
              MaterialCardSkeleton(),
            ],
          },
          const SizedBox(height: 12),
          if (_tab == _Tab.downloaded)
            _OfflineBanner(
              onCheck: () {
                ref.invalidate(downloadedMaterialsProvider);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Материалдар бұлтпен синхрондалды'),
                      duration: Duration(seconds: 2),
                    ),
                  );
              },
            )
          else
            const _SavedInfo(),
        ],
      ),
    );
  }
}

/// «☁ Жүктелгендер (18) | 🔖 Сақталғандар (34)» ауыстырғышы
class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.tab,
    required this.downloaded,
    required this.saved,
    required this.onSelect,
  });
  final _Tab tab;
  final int? downloaded;
  final int? saved;
  final ValueChanged<_Tab> onSelect;

  @override
  Widget build(BuildContext context) {
    String label(String text, int? n) => n == null ? text : '$text ($n)';
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _tabsBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _TabButton(
              icon: Symbols.cloud_done,
              label: label('Жүктелгендер', downloaded),
              active: tab == _Tab.downloaded,
              onTap: () => onSelect(_Tab.downloaded),
            ),
          ),
          Expanded(
            child: _TabButton(
              icon: Symbols.bookmark,
              label: label('Сақталғандар', saved),
              active: tab == _Tab.saved,
              onTap: () => onSelect(_Tab.saved),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppText.muted;
    return Material(
      color: active ? MColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              fill: icon == Symbols.cloud_done ? 1 : 0,
              color: color,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _inter,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 18 / 14,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Барлық пәндер | Биология (6) | Математика (8) | …» — көлденең тізім
class _SubjectChips extends StatelessWidget {
  const _SubjectChips({
    required this.subjects,
    required this.selected,
    required this.onSelect,
  });
  final Map<String, int> subjects;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'Барлық пәндер',
            active: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final e in subjects.entries) ...[
            const SizedBox(width: 3),
            _Chip(
              label: '${e.key} (${e.value})',
              active: selected == e.key,
              onTap: () => onSelect(e.key),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? MColors.primary : Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: _inter,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 16 / 13,
                color: active ? Colors.white : AppText.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// «Жақында жүктелгендер ⌄» / «Жақында сақталғандар ⌄» — сұрыптау
class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sort,
    required this.recentLabel,
    required this.onSelect,
  });
  final _Sort sort;
  final String recentLabel;
  final ValueChanged<_Sort> onSelect;

  @override
  Widget build(BuildContext context) {
    final labels = {
      _Sort.recent: recentLabel,
      _Sort.title: 'Атауы бойынша (А–Я)',
    };
    const style = TextStyle(
      fontFamily: _inter,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      height: 16 / 13,
      color: AppText.link,
    );
    return PopupMenuButton<_Sort>(
      onSelected: onSelect,
      color: Colors.white,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        for (final e in labels.entries)
          PopupMenuItem(
            value: e.key,
            child: Text(
              e.value,
              style: e.key == sort ? style : style.copyWith(color: AppText.ink),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labels[sort]!, style: style),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppText.link,
            ),
          ],
        ),
      ),
    );
  }
}

/// «Материалдар офлайн сақталған · Бұлтпен толық синхрондалған · Тексеру»
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onCheck});
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 9, 8, 9),
      decoration: BoxDecoration(
        color: _tabsBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Symbols.cloud_sync, size: 20, color: MColors.primary),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Материалдар офлайн сақталған',
                  style: TextStyle(
                    fontFamily: _inter,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 17 / 13,
                    color: AppText.ink,
                  ),
                ),
                Text(
                  'Бұлтпен толық синхрондалған',
                  style: TextStyle(
                    fontFamily: _inter,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppText.muted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCheck,
            style: TextButton.styleFrom(
              foregroundColor: AppText.link,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: const Text(
              'Тексеру',
              style: TextStyle(
                fontFamily: _inter,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppText.link,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Қажетті құжаттар үнемі қол астында» — сақталғандар астындағы түсініктеме
class _SavedInfo extends StatelessWidget {
  const _SavedInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: BoxDecoration(
        color: _infoBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Symbols.bookmark, size: 22, color: AppText.slate),
          ),
          const SizedBox(height: 12),
          const Text(
            'Қажетті құжаттар үнемі қол астында',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 22 / 16,
              color: AppText.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ұнаған материалдар мен сабақ жоспарларын бетбелгіге қосып, сабақ барысында интернетсіз де оңай пайдаланыңыз.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _inter,
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 15 / 12,
              color: AppText.muted,
            ),
          ),
        ],
      ),
    );
  }
}
