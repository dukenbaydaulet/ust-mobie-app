import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/typography.dart';
import '../material_detail.dart';

/// Құжатты бір тұтас «қағаз» ретінде салады (беттерге бөлінбейді).
/// [scale] — Document Reader-дегі үлкейту (1.0 = 100%).
class DocumentView extends StatelessWidget {
  const DocumentView({super.key, required this.blocks, this.scale = 1});
  final List<DocBlock> blocks;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final body = AppText.hintText.copyWith(
      color: AppText.ink,
      fontSize: 12 * s,
      height: 1.45,
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in blocks) ...[
            switch (b) {
              DocHeading(:final text) => Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppText.label.copyWith(fontSize: 12 * s, height: 1.35),
                ),
              ),
              // Бөлім тақырыбы: сол жағында қою сызық
              DocSection(:final number, :final title) => IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3 * s,
                      decoration: BoxDecoration(
                        color: AppText.ink,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    Expanded(
                      child: Text(
                        '$number. $title',
                        style: AppText.label.copyWith(
                          fontSize: 13 * s,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DocParagraph(:final text) => Text(text, style: body),
              // Слайд / бет суреті — ені бойынша
              DocImage(:final url) => ClipRRect(
                borderRadius: BorderRadius.circular(4 * s),
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : AspectRatio(
                          aspectRatio: 1 / 1.414,
                          child: ColoredBox(color: const Color(0xFFF1F3F6)),
                        ),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              // Мәліметтер (пән, сынып, күні…) сұр қорапта, екі бағанмен
              DocFields(:final fields) => Container(
                width: double.infinity,
                padding: EdgeInsets.all(10 * s),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EBF2),
                  borderRadius: BorderRadius.circular(8 * s),
                ),
                child: LayoutBuilder(
                  builder: (context, box) => Wrap(
                    spacing: 12 * s,
                    runSpacing: 8 * s,
                    children: [
                      for (final (k, v) in fields)
                        SizedBox(
                          width: (box.maxWidth - 12 * s) / 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$k:',
                                style: body.copyWith(
                                  color: AppText.muted,
                                  fontSize: 10 * s,
                                ),
                              ),
                              Text(
                                v,
                                style: body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            },
            SizedBox(height: 10 * s),
          ],
        ],
      ),
    );
  }
}

/// Материалдың алдын ала көрінісі:
///  - backend құжат мәтінін / беттерін берсе — [DocumentView];
///  - әйтпесе PDF болса — файлдың өз беттері;
///  - Word / PowerPoint / Excel болса — Office Online (сайттағыдай);
///  - әйтпесе — «көрініс жоқ» жазуы.
class MaterialPreview extends StatelessWidget {
  const MaterialPreview({
    super.key,
    required this.detail,
    this.scale = 1,
    this.maxPages,
    this.onPageCount,
  });
  final MaterialDetail detail;
  final double scale;

  /// PDF-тен ең көбі неше бет көрсетіледі (null — бәрі)
  final int? maxPages;

  /// PDF ашылғанда бет санын хабарлайды
  final ValueChanged<int>? onPageCount;

  @override
  Widget build(BuildContext context) {
    final html = detail.previewHtml;
    if (html != null) {
      // Карточкада ұзын құжаттың басы ғана жүктеледі
      return HtmlDocumentView(
        html: html,
        scale: scale,
        maxHeight: maxPages != null ? 2400 : null,
      );
    }
    if (detail.document.isNotEmpty) {
      return DocumentView(blocks: detail.document, scale: scale);
    }
    final url = detail.fileUrl;
    if (url != null && detail.material.fileType == 'pdf') {
      return _PdfPages(url: url, maxPages: maxPages, onPageCount: onPageCount);
    }
    if (url != null && _officeTypes.contains(detail.material.fileType)) {
      // Карточкада — шағын терезе, оқу бетінде — экран биіктігіне жуық
      final height = maxPages != null
          ? 360.0
          : MediaQuery.sizeOf(context).height * 0.75;
      return SizedBox(
        height: height,
        child: _OfficeView(fileUrl: url),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Бұл материалдың алдын ала көрінісі жоқ.\n'
        'Толық нұсқасын жүктеп алыңыз.',
        textAlign: TextAlign.center,
        style: AppText.caption,
      ),
    );
  }
}

/// Сайттағы құжат көрінісі (`savehtml`) — сайттағы CSS-пен, браузерде.
///  - әдепкі: биіктігі мазмұнына қарай өзгереді, сыртқы тізіммен бірге айналады
///    (материал беті; [maxHeight]-тен аспайды);
///  - [scrollable]: берілген орынды толтырып, ішінен айналады (оқу беті —
///    ұзын құжатты бір биік бетке салуға Android WebView-тің шамасы жетпейді).
class HtmlDocumentView extends StatefulWidget {
  const HtmlDocumentView({
    super.key,
    required this.html,
    this.scale = 1,
    this.maxHeight,
    this.scrollable = false,
    this.bottomPadding = 0,
    this.onScroll,
  });
  final String html;
  final double scale;

  /// Ең үлкен биіктігі (null — шектеусіз)
  final double? maxHeight;
  final bool scrollable;

  /// Құжаттың астындағы бос орын (батырмалар жаппауы үшін)
  final double bottomPadding;

  /// Айналдырғанда: (үлесі 0..1, A4 бойынша шамаланған бет саны)
  final void Function(double progress, int pages)? onScroll;

  @override
  State<HtmlDocumentView> createState() => _HtmlDocumentViewState();
}

class _HtmlDocumentViewState extends State<HtmlDocumentView> {
  late final WebViewController _controller;
  double _height = 400;
  bool _loading = true;

  /// Сайттағы `.pdf_img_text` стильдері (material_slug.vue)
  static const _css =
      '''
    html, body { margin: 0; background: #fff; }
    body {
      padding: 8px 10px; color: #000; word-wrap: break-word;
      font-family: "Times New Roman", "Noto Serif", serif;
      -webkit-text-size-adjust: none;
    }
    /* Көшіруге болмайды: мәтін белгіленбейді, ұзақ басқанда мәзір шықпайды */
    * {
      -webkit-user-select: none !important; user-select: none !important;
      -webkit-touch-callout: none !important;
    }
    img { pointer-events: none; }
    img {
      padding: 10px; max-width: 100%; height: auto; margin: 0 auto;
      display: block; box-sizing: border-box;
      box-shadow: 0 0 16px 2px rgba(34, 60, 80, 0.2);
    }
    p { margin: 20px 0; margin-left: 0 !important; }
    span, font { line-height: 20px; }
    table { max-width: 100% !important; }
    iframe { width: 100%; height: 575px; border: 0; }
    /* Айналдырылмаған Word: Office Online-ның төменгі жолағын (бет нөмірі,
       масштаб) жасырамыз — iframe жолақ биіктігіне ұзынырақ, артығы кесіледі */
    [data="not-converted-word"] { height: 575px; overflow: hidden; }
    [data="not-converted-word"] iframe { height: calc(100% + ${_officeBarHeight}px); }
  ''';

  String get _page =>
      '''<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
<style>$_css body { padding-bottom: ${widget.bottomPadding}px; }
${widget.scrollable ? '[data="not-converted-word"] { height: calc(100vh - 24px); }' : ''}</style>
</head><body>${widget.html}
<script>
  function report() {
    var h = document.documentElement.scrollHeight;
    Height.postMessage(String(h));
    var max = Math.max(1, h - window.innerHeight);
    var pageH = document.body.clientWidth * 1.414;
    Scroll.postMessage((window.scrollY / max) + ',' + Math.max(1, Math.ceil(h / pageH)));
  }
  ['copy', 'cut', 'contextmenu', 'selectstart', 'dragstart'].forEach(function (t) {
    document.addEventListener(t, function (e) { e.preventDefault(); }, true);
  });
  new ResizeObserver(report).observe(document.body);
  window.addEventListener('load', report);
  window.addEventListener('scroll', report, { passive: true });
</script></body></html>''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'Height',
        onMessageReceived: (m) {
          final h = double.tryParse(m.message);
          if (h == null || h <= 0 || !mounted) return;
          // Ішінен айналатын түрде биіктік өзгермейді
          if (widget.scrollable) {
            if (_loading) setState(() => _loading = false);
            return;
          }
          setState(() {
            _height = h;
            _loading = false;
          });
        },
      )
      ..addJavaScriptChannel(
        'Scroll',
        onMessageReceived: (m) {
          final parts = m.message.split(',');
          final progress = double.tryParse(parts.first) ?? 0;
          final pages = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;
          widget.onScroll?.call(progress.clamp(0, 1).toDouble(), pages);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _applyZoom();
            if (mounted) setState(() => _loading = false);
          },
          // Құжаттағы сілтемелерге өтпейміз (Office Online iframe-і жүктеле береді)
          onNavigationRequest: (r) =>
              r.isMainFrame && !r.url.startsWith('about:')
              ? NavigationDecision.prevent
              : NavigationDecision.navigate,
        ),
      )
      ..loadHtmlString(_page, baseUrl: 'https://api.ust.kz/storage/files/');
  }

  @override
  void didUpdateWidget(HtmlDocumentView old) {
    super.didUpdateWidget(old);
    if (old.scale != widget.scale) _applyZoom();
  }

  /// Оқу бетіндегі үлкейту: мәтін өлшемі де, ені де бірге өзгереді
  void _applyZoom() {
    _controller.runJavaScript(
      'document.body.style.zoom = "${widget.scale}"; report();',
    );
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.maxHeight;
    final height = widget.scrollable
        ? null
        : max == null
        ? _height
        : _height.clamp(0, max).toDouble();
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          _NoLongPress(
            child: WebViewWidget(
              controller: _controller,
              // Толық экранда браузер өзі айналады
              gestureRecognizers: widget.scrollable
                  ? _scrollGestures
                  : const {},
            ),
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Браузердің ішін саусақпен айналдыру
final _scrollGestures = <Factory<OneSequenceGestureRecognizer>>{
  Factory<VerticalDragGestureRecognizer>(VerticalDragGestureRecognizer.new),
  Factory<HorizontalDragGestureRecognizer>(HorizontalDragGestureRecognizer.new),
};

/// Ұзақ басуды браузерге жібермейді — мәтін белгілеу мен «Көшіру» мәзірі
/// ашылмайды. Office Online-ға (басқа сайт) осылай ғана тыйым салуға болады.
class _NoLongPress extends StatelessWidget {
  const _NoLongPress({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      GestureDetector(onLongPress: () {}, child: child);
}

/// Office Online-ның төменгі жолағының биіктігі (PAGE 1 OF 3, масштаб)
const _officeBarHeight = 30.0;

const _officeTypes = {'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'rtf'};

/// Word / PowerPoint файлды Microsoft Office Online арқылы көрсетеді
/// (сайттағы iframe сияқты). Файл интернеттен ашылатын адресте болуы керек —
/// жергілікті серверден (10.0.2.2, 127.0.0.1) Microsoft оны ала алмайды.
class _OfficeView extends StatefulWidget {
  const _OfficeView({required this.fileUrl});
  final String fileUrl;

  @override
  State<_OfficeView> createState() => _OfficeViewState();
}

class _OfficeViewState extends State<_OfficeView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final viewer = Uri.https('view.officeapps.live.com', '/op/embed.aspx', {
      'src': widget.fileUrl,
    });
    if (_localFile) return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) {
              if (mounted) setState(() => _failed = true);
            }
          },
        ),
      )
      ..loadRequest(viewer);
  }

  /// Жергілікті сервер (эмулятордан тексергенде) — Microsoft оған қол жеткізе алмайды
  bool get _localFile {
    final host = Uri.tryParse(widget.fileUrl)?.host ?? '';
    return host == '10.0.2.2' || host == '127.0.0.1' || host == 'localhost';
  }

  @override
  Widget build(BuildContext context) {
    if (_localFile) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Text(
          'Word / PowerPoint көрінісі Office Online арқылы ашылады.\n'
          'Файл жергілікті серверде болғандықтан, мұнда көрсетілмейді — '
          'нақты серверде (ust.kz) көрінеді.',
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
      );
    }
    if (_failed) return const _PageSkeleton(failed: true);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          // Office Online-ның төменгі жолағы кесіліп қалуы үшін браузер
          // жолақ биіктігіне ұзынырақ
          LayoutBuilder(
            builder: (context, box) => OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: box.maxHeight + _officeBarHeight,
              maxHeight: box.maxHeight + _officeBarHeight,
              child: _NoLongPress(
                child: WebViewWidget(
                  controller: _controller,
                  // Сыртқы тізім айналса да, құжаттың ішін саусақпен айналдыруға болады
                  gestureRecognizers: _scrollGestures,
                ),
              ),
            ),
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// PDF файлдың беттері — бірінен соң бірі, ені бойынша
class _PdfPages extends StatelessWidget {
  const _PdfPages({required this.url, this.maxPages, this.onPageCount});
  final String url;
  final int? maxPages;
  final ValueChanged<int>? onPageCount;

  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder.uri(
      Uri.parse(url),
      loadingBuilder: (_) => const _PageSkeleton(),
      errorBuilder: (_, _, _) => const _PageSkeleton(failed: true),
      builder: (context, doc) {
        if (doc == null) return const _PageSkeleton();
        final pages = doc.pages;
        if (onPageCount != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => onPageCount!(pages.length),
          );
        }
        final count = min(pages.length, maxPages ?? pages.length);
        return Column(
          children: [
            for (var i = 0; i < count; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : 8),
                child: AspectRatio(
                  aspectRatio: pages[i].width / pages[i].height,
                  child: PdfPageView(
                    document: doc,
                    pageNumber: i + 1,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Бет жүктелгенше — A4 пішінді ақ бет
class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton({this.failed = false});
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1.414,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: failed
            ? Text('Файлды ашу мүмкін болмады', style: AppText.caption)
            : const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
      ),
    );
  }
}
