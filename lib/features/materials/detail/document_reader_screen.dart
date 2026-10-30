import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/typography.dart';
import '../material_detail.dart';
import '../widgets/material_widgets.dart';
import 'detail_controller.dart';
import 'doc_page_view.dart';

// Түстер дизайн суретінен өлшеп алынды
const _readerBg = Color(0xFF64748B);
const _badgeBg = Color(0xFFD8E0EE);
const _strip = Color(0xFFEFF1F3);
const _pageBg = Color(0xFFE5EFFF);
const _sizeBadge = Color(0xFF3470CD);

/// Құжатты толық экранда оқу (материал бетінің үстінен ашылады).
Future<void> showDocumentReader(BuildContext context, MaterialDetail detail) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    // Статус-бар мен төменгі жолақтың астына дейін созылады,
    // шегіністерді _Reader өзі ескереді
    useSafeArea: false,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: _readerBg,
      child: _Reader(detail: detail),
    ),
  );
}

/// Сілтеме арқылы ашылғанда (/material/:id/read) — толық экран.
class DocumentReaderScreen extends ConsumerWidget {
  const DocumentReaderScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(materialDetailProvider(id));
    return Scaffold(
      backgroundColor: _readerBg,
      body: detail.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (_, _) => Center(
          child: Text(
            'Құжатты ашу мүмкін болмады',
            style: AppText.caption.copyWith(color: Colors.white),
          ),
        ),
        data: (d) => _Reader(detail: d),
      ),
    );
  }
}

class _Reader extends ConsumerStatefulWidget {
  const _Reader({required this.detail});
  final MaterialDetail detail;

  @override
  ConsumerState<_Reader> createState() => _ReaderState();
}

class _ReaderState extends ConsumerState<_Reader> {
  static const _zooms = [0.75, 1.0, 1.25, 1.5, 2.0];
  int _zoom = 1; // _zooms ішіндегі индекс (100%)
  bool _busy = false;

  // Құжат беттерге бөлінбейді, сондықтан бет нөмірін
  // айналдыру орнынан A4 пішімі бойынша шамалап есептейміз.
  final _scroll = ScrollController();
  double _pageHeight = 1;
  int _page = 1;
  int _pages = 1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updatePage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePage());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// PDF ашылғанда оның нақты бет саны
  int? _pdfPages;

  /// Нақты бет саны: PDF-тің өзі, backend `page_count`, немесе слайд суреттері.
  /// Белгісіз болса — null, санағыш көрсетілмейді (шамамен санау қате шығады,
  /// мысалы Office Online ішіндегі Word құжатында).
  int? get _exactPages {
    if (_pdfPages != null) return _pdfPages;
    final known = widget.detail.pageCount;
    if (known != null && known > 0) return known;
    final doc = widget.detail.document;
    if (doc.isNotEmpty && doc.every((b) => b is DocImage)) return doc.length;
    return null;
  }

  void _setPdfPages(int n) {
    if (_pdfPages == n || !mounted) return;
    _pdfPages = n;
    _updatePage();
  }

  void _updatePage() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final total = pos.maxScrollExtent + pos.viewportDimension;
    // Backend бет санын білсе — соны, әйтпесе A4 бойынша шамалаймыз
    // PDF-тің өз бет саны дәлірек; әйтпесе backend-тегі page_count
    final known = _exactPages;
    final pages = known != null && known > 0
        ? known
        : (total / _pageHeight).ceil().clamp(1, 999);
    // Айналдыру үлесі бойынша қазіргі бет
    final progress = pos.maxScrollExtent <= 0
        ? 0.0
        : (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    final page = known != null && known > 0
        ? (progress * (pages - 1)).round() + 1
        : ((pos.pixels + pos.viewportDimension / 2) / _pageHeight)
                  .floor()
                  .clamp(0, pages - 1) +
              1;
    if (page != _page || pages != _pages) {
      setState(() {
        _page = page;
        _pages = pages;
      });
    }
  }

  /// HTML көрінісі айналғанда — бет нөмірі (backend бет санын білсе — соны)
  void _onHtmlScroll(double progress, int estimated) {
    final known = widget.detail.pageCount;
    final pages = known != null && known > 0 ? known : estimated;
    final page = (progress * (pages - 1)).round() + 1;
    if (page != _page || pages != _pages) {
      setState(() {
        _page = page;
        _pages = pages;
      });
    }
  }

  void _setZoom(int z) {
    setState(() => _zoom = z);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePage());
  }

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
    final d = widget.detail;
    final scale = _zooms[_zoom];
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Column(
      children: [
        _Header(
          detail: d,
          page: _page,
          pages: _pages,
          showCounter: _exactPages != null,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final pageWidth = (box.maxWidth - 24) * scale;
              _pageHeight = pageWidth * 1.414;
              return Stack(
                children: [
                  // Сайттағы HTML көрінісі — браузер өзі айналады
                  if (d.previewHtml != null)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: HtmlDocumentView(
                            html: d.previewHtml!,
                            scale: scale,
                            scrollable: true,
                            bottomPadding: 84 + bottom,
                            onScroll: _onHtmlScroll,
                          ),
                        ),
                      ),
                    )
                  else
                    // Құжат бір тұтас, беттерге бөлінбейді
                    Positioned.fill(
                      child: SingleChildScrollView(
                        controller: _scroll,
                        padding: EdgeInsets.fromLTRB(12, 12, 12, 84 + bottom),
                        child: SingleChildScrollView(
                          // Үлкейткенде көлденеңінен де айналады
                          scrollDirection: Axis.horizontal,
                          // Кішірейткенде құжат ортада тұрады
                          child: SizedBox(
                            width: max(pageWidth, box.maxWidth - 24),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: pageWidth,
                                child: MaterialPreview(
                                  detail: d,
                                  scale: scale,
                                  onPageCount: _setPdfPages,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 16 + bottom,
                    child: Row(
                      children: [
                        _DownloadPill(
                          fileSize: d.fileSize,
                          busy: _busy,
                          onTap: _download,
                        ),
                        const Spacer(),
                        _ZoomPill(
                          percent: (scale * 100).round(),
                          onIn: _zoom == _zooms.length - 1
                              ? null
                              : () => _setZoom(_zoom + 1),
                          onOut: _zoom == 0 ? null : () => _setZoom(_zoom - 1),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Жоғарғы бөлік:
///  ✕   Document Reader   [📖 1 / 12]
///  [DOCX] Атауы • 1.8 MB
class _Header extends StatelessWidget {
  const _Header({
    required this.detail,
    required this.page,
    required this.pages,
    required this.showCounter,
  });
  final MaterialDetail detail;
  final int page;
  final int pages;

  /// Бет саны нақты белгілі болғанда ғана
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    final m = detail.material;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            height: 52 + MediaQuery.paddingOf(context).top,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Document Reader',
                  style: AppText.topBarTitle.copyWith(fontSize: 17),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppText.ink),
                  ),
                ),
                if (showCounter)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _PageCounter(page: page, pages: pages),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: _strip,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    m.fileType.toUpperCase(),
                    style: AppText.tag.copyWith(
                      color: AppText.link,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    m.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.chip.copyWith(fontSize: 13),
                  ),
                ),
                Text(
                  ' • ${detail.fileSize}',
                  style: AppText.caption.copyWith(color: MColors.hint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «📖 1 / 12» — бет нөмірі
class _PageCounter extends StatelessWidget {
  const _PageCounter({required this.page, required this.pages});
  final int page;
  final int pages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const ShapeDecoration(color: _pageBg, shape: StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_rounded, size: 16, color: MColors.primary),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$page',
                  style: const TextStyle(color: MColors.primary),
                ),
                TextSpan(text: ' / $pages'),
              ],
            ),
            style: AppText.chipStrong.copyWith(color: AppText.muted),
          ),
        ],
      ),
    );
  }
}

const _pillShadow = [
  BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4)),
];

/// «⤓ Жүктеу [1.8 MB]» — дөңгелек көк батырма
class _DownloadPill extends StatelessWidget {
  const _DownloadPill({
    required this.fileSize,
    required this.busy,
    required this.onTap,
  });
  final String fileSize;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        shadows: _pillShadow,
      ),
      child: Material(
        color: AppText.link,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: busy ? null : onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Symbols.download,
                          size: 22,
                          weight: 500,
                          color: Colors.white,
                        ),
                  const SizedBox(width: 6),
                  Text(
                    'Жүктеу',
                    style: AppText.action.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      height: 20 / 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: const ShapeDecoration(
                      color: _sizeBadge,
                      shape: StadiumBorder(),
                    ),
                    child: Text(
                      fileSize,
                      style: AppText.chipStrong.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                      ),
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

/// «+ 100% −» — ақ дөңгелек үлкейту басқармасы
class _ZoomPill extends StatelessWidget {
  const _ZoomPill({required this.percent, this.onIn, this.onOut});
  final int percent;
  final VoidCallback? onIn;
  final VoidCallback? onOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: StadiumBorder(),
        shadows: _pillShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onIn,
            color: AppText.ink,
            disabledColor: MColors.faint,
            icon: const Icon(Icons.add, size: 20),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$percent%',
              textAlign: TextAlign.center,
              style: AppText.chip.copyWith(color: AppText.muted, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: onOut,
            color: AppText.ink,
            disabledColor: MColors.faint,
            icon: const Icon(Icons.remove, size: 20),
          ),
        ],
      ),
    );
  }
}
