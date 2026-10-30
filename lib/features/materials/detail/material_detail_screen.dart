import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/typography.dart';
import '../../../core/api_client.dart';
import '../material_detail.dart';
import '../widgets/material_widgets.dart';
import 'detail_controller.dart';
import 'detail_sheets.dart';
import 'doc_page_view.dart';
import 'document_reader_screen.dart';

/// Материалдың жеке беті.
class MaterialDetailScreen extends ConsumerWidget {
  const MaterialDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(materialDetailProvider(id));
    return Scaffold(
      backgroundColor: MColors.page,
      body: Column(
        children: [
          _TopBar(
            onShare: detail.value == null
                ? null
                : () => SharePlus.instance.share(
                    ShareParams(
                      text:
                          '${detail.value!.material.title}\nhttps://ust.kz/word/$id',
                    ),
                  ),
          ),
          Expanded(
            child: detail.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _Error(
                onRetry: () => ref.invalidate(materialDetailProvider(id)),
              ),
              data: (d) => _Body(detail: d),
            ),
          ),
        ],
      ),
      bottomNavigationBar: detail.value == null
          ? null
          : _BottomBar(detail: detail.value!),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.onShare});
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        height: 56 + MediaQuery.paddingOf(context).top,
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: AppText.ink),
            ),
            const Expanded(
              child: Text(
                'Материал',
                textAlign: TextAlign.center,
                style: AppText.topBarTitle,
              ),
            ),
            IconButton(
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined, color: AppText.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.detail});
  final MaterialDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = detail;
    final similar = ref.watch(similarMaterialsProvider(d.material.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(d.material.title, style: AppText.pageTitle.copyWith(height: 1.25)),
        const SizedBox(height: 16),
        _Card(
          child: _Expandable(
            title: 'Сипаттама',
            collapsed: Text(
              d.material.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppText.description.copyWith(height: 1.4),
            ),
            expanded: Text(
              d.fullDescription,
              style: AppText.description.copyWith(height: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Preview(detail: d),
        const SizedBox(height: 12),
        _Card(child: _Properties(detail: d)),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => isLoggedIn(ref)
                ? showComplaintDialog(context, material: d.material)
                : showLoginRequiredSheet(
                    context,
                    material: d.material,
                    fileSize: d.fileSize,
                    purpose: 'Шағым жазу үшін',
                  ),
            child: Text('Шағым жасау', style: AppText.caption),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Ұқсас материалдар', style: AppText.sectionTitle),
            const SizedBox(width: 6),
            Text(
              '(${d.similarCount})',
              style: AppText.caption.copyWith(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...switch (similar) {
          AsyncData(:final value) => [
            for (final m in value) ...[
              MaterialCard(
                material: m,
                onTap: () => context.push('/material/${m.id}'),
              ),
              const SizedBox(height: 8),
            ],
          ],
          AsyncError() => const <Widget>[],
          _ => [const MaterialCardSkeleton()],
        },
      ],
    );
  }
}

/// Ақ карточка
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// «Толығырақ ⌄ / Жасыру ⌃» сілтемесі
class _MoreLink extends StatelessWidget {
  const _MoreLink({
    required this.expanded,
    required this.onTap,
    this.moreLabel = 'Толығырақ',
  });
  final bool expanded;
  final VoidCallback onTap;
  final String moreLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expanded ? 'Жасыру' : moreLabel,
              style: AppText.smallLink.copyWith(fontWeight: FontWeight.w600),
            ),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: AppText.link,
            ),
          ],
        ),
      ),
    );
  }
}

/// Тақырып + қысқа/толық мазмұн
class _Expandable extends StatefulWidget {
  const _Expandable({
    required this.title,
    required this.collapsed,
    required this.expanded,
  });
  final String title;
  final Widget collapsed;
  final Widget expanded;

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: AppText.label),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _open ? widget.expanded : widget.collapsed,
        ),
        const SizedBox(height: 6),
        _MoreLink(expanded: _open, onTap: () => setState(() => _open = !_open)),
      ],
    );
  }
}

/// Құжаттың алдын ала көрінісі + «Толық экранда ашу»
class _Preview extends StatelessWidget {
  const _Preview({required this.detail});
  final MaterialDetail detail;

  @override
  Widget build(BuildContext context) {
    void open() => showDocumentReader(context, detail);
    return Container(
      height: 380,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Құжаттың ішін осы жерде де төмен айналдырып оқуға болады
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 70),
              child: MaterialPreview(detail: detail, scale: 0.85, maxPages: 3),
            ),
          ),
          // Төменгі жағы біртіндеп ағарады
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00FFFFFF), Colors.white],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: MColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: open,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fullscreen,
                        size: 16,
                        color: AppText.link,
                      ),
                      const SizedBox(width: 4),
                      Text('Толық экранда ашу', style: AppText.smallLink),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Мінездеме»: сынып, пән, бағыт, формат.
/// «Толығырақ оқу» — осы карточканың ішінде толық тізім ашылады
/// (+ уақыт, жүктеулер, көрілім).
class _Properties extends StatefulWidget {
  const _Properties({required this.detail});
  final MaterialDetail detail;

  @override
  State<_Properties> createState() => _PropertiesState();
}

class _PropertiesState extends State<_Properties> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Мінездеме', style: AppText.cardTitle),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _PropertyRows(detail: widget.detail, full: _open),
        ),
        const SizedBox(height: 8),
        _MoreLink(
          expanded: _open,
          moreLabel: 'Толығырақ оқу',
          onTap: () => setState(() => _open = !_open),
        ),
      ],
    );
  }
}

/// Мінездеме жолдары: «Сыныбы: … 6 сынып»
class _PropertyRows extends StatelessWidget {
  const _PropertyRows({required this.detail, required this.full});
  final MaterialDetail detail;
  final bool full;

  static final _key = AppText.topBarTitle.copyWith(
    fontWeight: FontWeight.w400,
    color: AppText.slate,
  );
  static final _value = AppText.topBarTitle.copyWith(color: AppText.slate);

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final m = d.material;
    final ext = m.fileType.isEmpty
        ? ''
        : m.fileType[0].toUpperCase() + m.fileType.substring(1);
    final rows = [
      ('Сыныбы:', m.grade ?? '—'),
      ('Пән:', m.subject ?? '—'),
      ('Бағыты:', d.direction),
      ('Форматы:', ext),
      if (full) ...[
        ('Уақыты:', d.date),
        ('Жүктеулер:', '${d.downloads}'),
        ('Көрілім:', '${d.views}'),
      ],
    ];
    return Column(
      children: [
        for (final (k, v) in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF5F7FA))),
            ),
            child: Row(
              children: [
                Text(k, style: _key),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    v,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _value,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BottomBar extends ConsumerStatefulWidget {
  const _BottomBar({required this.detail});
  final MaterialDetail detail;

  @override
  ConsumerState<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends ConsumerState<_BottomBar> {
  bool _busy = false;

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      await downloadMaterial(context, ref, widget.detail);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.detail.material.id;
    final saved = ref.watch(savedMaterialsProvider).contains(id);
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _busy ? null : _download,
                style: FilledButton.styleFrom(
                  backgroundColor: MColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Symbols.vertical_align_bottom, size: 22),
                label: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    'Жүктеп алу',
                    style: AppText.action.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: MColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                // Қонақ сақтай алмайды — алдымен кіру керек
                if (!isLoggedIn(ref)) {
                  showLoginRequiredSheet(
                    context,
                    material: widget.detail.material,
                    fileSize: widget.detail.fileSize,
                    purpose: 'Материалды сақтау үшін',
                  );
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                String text;
                try {
                  final nowSaved = await ref
                      .read(savedMaterialsProvider.notifier)
                      .toggle(id);
                  text = nowSaved
                      ? 'Материалдарымға сақталды'
                      : 'Сақталғандардан алынды';
                } catch (e) {
                  text = errorMessage(e);
                }
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(text),
                      duration: const Duration(seconds: 2),
                    ),
                  );
              },
              child: SizedBox(
                width: 50,
                height: 50,
                child: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: AppText.link,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 36, color: MColors.hint),
          const SizedBox(height: 8),
          Text('Материалды жүктеу мүмкін болмады', style: AppText.caption),
          TextButton(onPressed: onRetry, child: const Text('Қайталау')),
        ],
      ),
    );
  }
}
