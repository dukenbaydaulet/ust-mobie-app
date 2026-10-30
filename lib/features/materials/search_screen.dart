import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/typography.dart';
import 'material.dart';
import 'materials_controller.dart';
import 'materials_list_view.dart';
import 'materials_repository.dart';
import 'widgets/filter_sheets.dart';
import 'widgets/material_widgets.dart';

/// Іздеу беті. Екі күйі бар:
///  - бастапқы: соңғы іздеулер, танымал сұраулар, санаттар (+ теру кезінде ұсыныстар);
///  - нәтиже: сүзгілер мен табылған материалдар (немесе «Ешнәрсе табылмады»).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  /// null — бастапқы күй, әйтпесе нәтижелер көрсетіледі
  String? _submitted;
  MaterialFilters _filters = const MaterialFilters();
  List<SearchSuggestion> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final list = await ref
          .read(materialsRepositoryProvider)
          .suggestions(value);
      if (mounted && _text.text == value) setState(() => _suggestions = list);
    });
  }

  void _submit(
    String query, {
    MaterialFilters filters = const MaterialFilters(),
  }) {
    final q = query.trim();
    if (q.isEmpty) return;
    ref.read(recentSearchesProvider.notifier).add(q);
    _text.text = q;
    _focus.unfocus();
    setState(() {
      _submitted = q;
      _filters = filters;
      _suggestions = const [];
    });
  }

  void _backToStart() {
    setState(() => _submitted = null);
    _focus.requestFocus();
  }

  void _clearText() {
    _text.clear();
    setState(() {
      _suggestions = const [];
      _submitted = null;
    });
    _focus.requestFocus();
  }

  Future<void> _openFilter(FilterKind kind) async {
    final result = await showFilterSheet(
      context,
      kind: kind,
      initial: _filters,
      query: _submitted ?? '',
    );
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final results = _submitted != null;
    return Scaffold(
      backgroundColor: MColors.page,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            LogoHeader(
              onBack: results ? () => Navigator.of(context).pop() : null,
            ),
            Expanded(child: results ? _results() : _start()),
          ],
        ),
      ),
    );
  }

  // ---------- Бастапқы күй ----------

  Widget _start() {
    final showSuggestions =
        _focus.hasFocus &&
        _text.text.trim().isNotEmpty &&
        _suggestions.isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: SearchBox(
                  controller: _text,
                  focusNode: _focus,
                  hint: 'Материал іздеу',
                  focused: true,
                  onChanged: _onChanged,
                  onSubmitted: _submit,
                  onClear: _text.text.isEmpty ? null : _clearText,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Болдырмау', style: AppText.action),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              _startContent(),
              if (showSuggestions)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 6,
                  child: _suggestionsCard(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _startContent() {
    final recent = ref.watch(recentSearchesProvider);
    final popular = ref.watch(popularQueriesProvider).value ?? const [];
    final categories = ref.watch(categoriesProvider).value ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (recent.isNotEmpty) ...[
          SectionTitle(
            // Тақырыптағы белгіше — қарапайым сағат (жолдардағы белгіше өзгеріссіз)
            icon: Icons.schedule,
            title: 'Соңғы іздеулер',
            action: 'Тазалау',
            onAction: () => ref.read(recentSearchesProvider.notifier).clear(),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (final q in recent.take(5))
                  _RecentRow(
                    text: q,
                    onTap: () => _submit(q),
                    onRemove: () =>
                        ref.read(recentSearchesProvider.notifier).remove(q),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        const SectionTitle(
          icon: Icons.local_fire_department,
          title: 'Танымал сұраулар',
          iconColor: MColors.orange,
          iconBackground: MColors.orangeSoft,
        ),
        const SizedBox(height: 10),
        PopularQueries(queries: popular, onTap: _submit),
        const SizedBox(height: 22),
        const SectionTitle(
          icon: Icons.category_outlined,
          title: 'Ұсынылатын санаттар',
          iconColor: MColors.primaryDark,
          iconBackground: MColors.primarySoft,
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          // Әйтпесе тор экранның жоғарғы шегінісін өзіне қосып алады
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            for (final c in categories)
              _CategoryCard(
                category: c,
                onTap: () => _submit(
                  c.name,
                  filters: MaterialFilters(subjects: {c.subjectId}),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _suggestionsCard() {
    final q = _text.text.trim().toLowerCase();
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ІЗДЕУ БОЙЫНША ҰСЫНЫСТАР',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: MColors.hint,
                      ),
                    ),
                  ),
                  Text(
                    '${_suggestions.length} сәйкестік',
                    style: const TextStyle(fontSize: 11, color: MColors.hint),
                  ),
                ],
              ),
            ),
            for (final s in _suggestions)
              InkWell(
                onTap: () => _submit(s.text),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        s.fromHistory ? Icons.history : Icons.search,
                        size: 18,
                        color: MColors.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          _highlight(s.text, q),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: MColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: MColors.chip,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.tag,
                          style: const TextStyle(
                            fontSize: 10,
                            color: MColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkResponse(
                        onTap: () {
                          _text.text = s.text;
                          _text.selection = TextSelection.collapsed(
                            offset: s.text.length,
                          );
                          _onChanged(s.text);
                        },
                        child: const Icon(
                          Icons.north_west,
                          size: 16,
                          color: MColors.hint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Сәйкес келген бөлікті көк түспен белгілейді.
  TextSpan _highlight(String text, String q) {
    final i = text.toLowerCase().indexOf(q);
    if (q.isEmpty || i < 0) return TextSpan(text: text);
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, i)),
        TextSpan(
          text: text.substring(i, i + q.length),
          style: const TextStyle(
            color: MColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(text: text.substring(i + q.length)),
      ],
    );
  }

  // ---------- Нәтижелер ----------

  Widget _results() {
    return MaterialsListView(
      key: ValueKey((_submitted, _filters)),
      query: (query: _submitted!, filters: _filters),
      showScrollTop: true,
      endText: (total) =>
          'Іздеу бойынша барлық ${formatNumber(total)} нәтиже жүктелді',
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SearchBox(
              controller: _text,
              readOnly: true,
              onTap: _backToStart,
              onClear: _clearText,
            ),
          ),
          FilterBar(
            filters: _filters,
            onSubjects: () => _openFilter(FilterKind.subjects),
            onDirections: () => _openFilter(FilterKind.directions),
            onGrades: () => _openFilter(FilterKind.grades),
            onClear: () => setState(() => _filters = const MaterialFilters()),
          ),
        ],
      ),
      empty: _EmptyResults(
        query: _submitted!,
        popular: ref.watch(popularQueriesProvider).value ?? const [],
        onPopular: _submit,
        onClear: _clearText,
        onCatalog: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.text,
    required this.onTap,
    required this.onRemove,
  });
  final String text;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: MColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, size: 16, color: MColors.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.listItem,
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16, color: MColors.faint),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});
  final MaterialCategory category;
  final VoidCallback onTap;

  /// (белгіше, белгіше түсі, фон) — түстер дизайннан өлшеп алынды.
  /// Көрнекілік пен Тәрбие сағаты суретте көрінбеді, сондықтан солардың
  /// палитрасына сай таңдалды.
  static (IconData, Color, Color) _style(String id) => switch (id) {
    'primary' => (
      Icons.backpack_outlined,
      MColors.primaryDark,
      const Color(0xFFDAE1FF),
    ),
    'math' => (
      Icons.calculate_outlined,
      const Color(0xFF435383),
      const Color(0xFFDDE9FF),
    ),
    'kazakh' => (
      Icons.translate,
      const Color(0xFF354574),
      const Color(0xFFDBE1FF),
    ),
    'history' => (Icons.groups_outlined, MColors.orange, MColors.orangeSoft),
    'visual' => (
      Icons.slideshow_outlined,
      const Color(0xFF93000A),
      const Color(0xFFFFDAD6),
    ),
    _ => (
      Icons.verified_outlined,
      MColors.primaryDark,
      const Color(0xFFDAE1FF),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = _style(category.subjectId);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const Spacer(),
                  const Icon(Icons.north_east, size: 16, color: MColors.faint),
                ],
              ),
              const Spacer(),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.tileTitle,
              ),
              const SizedBox(height: 2),
              Text(category.countLabel, style: AppText.caption),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Ешнәрсе табылмады» суретінің дөңгелек фоны
const _emptyCircle = Color(0xFFE9EAED);

/// «Ешнәрсе табылмады» күйі.
class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.query,
    required this.popular,
    required this.onPopular,
    required this.onClear,
    required this.onCatalog,
  });

  final String query;
  final List<String> popular;
  final ValueChanged<String> onPopular;
  final VoidCallback onClear;
  final VoidCallback onCatalog;

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Сөздердің дұрыс жазылуын (емлесін) тексеріңіз',
      'Басқа синоним немесе жалпырақ кілт сөздер қолданыңыз',
      'Пән мен сынып атауын бөлек жазып көріңіз (мыс: Қазақ тілі 5)',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5484D),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Материалдар табылмады', style: AppText.label),
            ],
          ),
          const SizedBox(height: 20),
          // Сурет экранның екі шетінен 90-нан шегініп, мүмкіндігінше үлкен тұрады.
          // material_not.svg ішіндегі JPEG flutter_svg-де салынбайды (pattern
          // қолдау жоқ), сондықтан SVG-дегідей етіп кодпен саламыз.
          Center(
            child: Builder(
              builder: (context) {
                final size = MediaQuery.sizeOf(context).width - 180;
                return Container(
                  width: size,
                  height: size,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: _emptyCircle,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        offset: Offset(0, 1),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  // Сұр дөңгелектің ортасында ақ жолақ (сурет) — дизайндағыдай
                  child: Image.asset(
                    'assets/images/material/material_not.jpg',
                    width: size,
                    fit: BoxFit.fitWidth,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Ешнәрсе табылмады',
              textAlign: TextAlign.center,
              style: AppText.emptyTitle,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  // Сұрау мәтіні қою түспен
                  TextSpan(
                    text: '«$query»',
                    style: const TextStyle(color: AppText.ink),
                  ),
                  const TextSpan(
                    text: ' сұрауы бойынша ешқандай оқу материалы табылмады. Сұрауды тексеріп, қайта көріңіз.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              // Екі жол бір-біріне тиіп қалмауы үшін 1.3
              style: AppText.description.copyWith(height: 1.3),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.lightbulb_outline,
                  title: 'Іздеу бойынша кеңестер',
                  small: true,
                  iconColor: MColors.primary,
                  iconBackground: MColors.primarySoft,
                ),
                const SizedBox(height: 10),
                for (final t in tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: MColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t, style: AppText.hintText)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(
            icon: Icons.local_fire_department,
            title: 'Танымал сұраулар',
            iconColor: MColors.orange,
            iconBackground: MColors.orangeSoft,
          ),
          const SizedBox(height: 10),
          PopularQueries(queries: popular, onTap: onPopular),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onClear,
              style: FilledButton.styleFrom(
                backgroundColor: MColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Іздеуді тазалау',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton.icon(
              onPressed: onCatalog,
              style: TextButton.styleFrom(
                backgroundColor: MColors.primarySoft,
                foregroundColor: MColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text(
                'Жалпы каталогты қарау',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
