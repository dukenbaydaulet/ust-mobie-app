import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../auth/user.dart';
import '../profile/profile_repository.dart' show offlineSaveKey;
import 'material.dart';
import 'widgets/material_widgets.dart' show formatNumber;
import 'material_detail.dart';
import 'materials_repository.dart';

/// Материалдар backend-тен — сайт қолданатын бар endpoint-тер (`/api/word/...`,
/// `/api/menin-materialdarym/...`) және мобильдіге арналған жаңалары
/// (`/api/mobile/...`, сипаттамасы — docs/backend-mobile-api-prompt.md).
/// Жаңасы әлі жоқ болса (404) — бар endpoint-ке ауысады: сүзгіде бір мән ғана,
/// сансыз, бағалау жазылмайды.
class ApiMaterialsRepository implements MaterialsRepository {
  ApiMaterialsRepository(this._dio, this._currentUser);
  final Dio _dio;

  /// Шағымға аты мен телефоны керек
  final User? Function() _currentUser;

  /// Backend бір бетте 20 материал береді (`paginate(20)`)
  static const _pageSize = 20;

  /// Материал беті `/word/{slug}-{id}` арқылы ашылады — slug тізімдерден жиналады
  final _slugs = <int, String>{};

  /// Жүктегенде файл атауы (материал бетінен)
  final _fileNames = <int, String>{};

  /// Backend-те жоқ (404) болған `/mobile/...` endpoint-тері және сол уақыт.
  /// Бір минут бойы қайта сұрамаймыз, сосын қайта тексереміз — backend-ке
  /// endpoint қосылса, қосымшаны қайта іске қоспай-ақ соған көшеміз.
  final _missingAt = <String, DateTime>{};
  static const _missingTtl = Duration(minutes: 1);

  bool _isMissing(String path) {
    final at = _missingAt[path];
    if (at == null) return false;
    if (DateTime.now().difference(at) < _missingTtl) return true;
    _missingAt.remove(path);
    return false;
  }

  /// Алдымен жаңа [mobilePath], ол жоқ болса (404) — бар [oldPath].
  Future<Response<dynamic>> _get(
    String mobilePath,
    String oldPath, [
    Map<String, dynamic>? params,
  ]) async {
    if (!_isMissing(mobilePath)) {
      try {
        return await _dio.get(mobilePath, queryParameters: params);
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        _missingAt[mobilePath] = DateTime.now();
      }
    }
    return _dio.get(oldPath, queryParameters: params);
  }

  // ---- Тізім және сүзгілер ----

  /// Бір топта бірнеше нұсқа үтірмен беріледі (backend қолдауы — промтта).
  Map<String, dynamic> _filterParams(String query, MaterialFilters f) => {
    if (query.trim().isNotEmpty) 'title': query.trim(),
    if (f.subjects.isNotEmpty) 'subject': f.subjects.join(','),
    if (f.directions.isNotEmpty) 'direction': f.directions.join(','),
    if (f.grades.isNotEmpty) 'class': f.grades.join(','),
  };

  @override
  Future<MaterialsPage> search({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
    int offset = 0,
    int limit = 10,
  }) async {
    final res = await _get('/mobile/materials', '/word', {
      ..._filterParams(query, filters),
      'page': offset ~/ _pageSize + 1,
    });
    final page = res.data['materials'] as Map<String, dynamic>;
    return MaterialsPage(
      items: _materials(page['data']),
      total: _int(page['total']),
      hasMore: _int(page['current_page']) < _int(page['last_page']),
    );
  }

  /// Пәндер, бағыттар, сыныптар. Алдымен сандарымен
  /// (`/mobile/materials/filter-counts`), ол әлі жоқ болса — сансыз (`getCategories`).
  Future<Map<String, List<FilterOption>>> _filters(
    String query,
    MaterialFilters f,
  ) async {
    const counts = '/mobile/materials/filter-counts';
    final withCount = !_isMissing(counts);
    final res = await _get(
      counts,
      '/word/getCategories',
      _filterParams(query, f),
    );
    final hasCounts = withCount && !_isMissing(counts);
    final result = {
      for (final k in ['subjects', 'directions', 'classes'])
        k: _options(
          res.data[k],
          withCount: hasCounts,
          classes: k == 'classes',
          includeAll: hasCounts,
        ),
    };
    // Санаулы тізім мүлде бос келсе (мыс. backend id = 1-ді «Барлығы» деп
    // алып тастаған, ал базада тек сол бар) — сансыз толық тізімді аламыз
    if (hasCounts && result.values.every((l) => l.isEmpty)) {
      final all = await _dio.get('/word/getCategories');
      return {
        for (final k in ['subjects', 'directions', 'classes'])
          k: _options(all.data[k], withCount: false, classes: k == 'classes'),
      };
    }
    return result;
  }

  /// «Барлық пәндер / материалдар / сыныптар» — материалдың өз белгісі
  /// (барлығына арналған), жеке нұсқа ретінде таңдалады. Тек `/mobile/...`
  /// бойынша сүзіледі — сайттың `/word` endpoint-і id = 1-ді елемейді, сондықтан
  /// ол кезде [_options] бұл нұсқаны шығармайды. Атауы бойынша тексереміз.
  static bool _isAll(Object? name) =>
      '${name ?? ''}'.trim().toLowerCase().startsWith('барлық');

  /// [classes] — сыныптар тізімі: тек соларда «Мектепке дейінгі» / «Басқа» бөлек шығады
  /// (пәндер мен бағыттарда да «Басқа» бар, оларға тимейміз).
  List<FilterOption> _options(
    Object? list, {
    required bool withCount,
    bool classes = false,
    bool includeAll = false,
  }) => [
    for (final o in (list as List? ?? const []))
      if (includeAll || !_isAll(o['name']))
        FilterOption(
          id: '${o['id']}',
          name: classes ? _optionName(o) : '${o['name'] ?? ''}',
          count: withCount ? _int(o['count']) : null,
          type: classes ? _optionType(o) : FilterOptionType.regular,
        ),
  ];

  /// Дизайндағы атаулар: «Мектепке дейінгі» мен «Басқа» қай API-ден келсе де бірдей.
  static String _optionName(Object? o) {
    final m = o as Map? ?? const {};
    return switch (_optionType(o)) {
      FilterOptionType.preschool => 'Мектепке дейінгі білім беру',
      FilterOptionType.other => 'Басқа санаттар (Колледж, әдіскерлер)',
      FilterOptionType.regular => '${m['display_name'] ?? m['name'] ?? ''}',
    };
  }

  /// filter-counts `type` береді; getCategories-те жоқ — атауы бойынша анықтаймыз.
  static FilterOptionType _optionType(Object? o) {
    final m = o as Map? ?? const {};
    switch (m['type']) {
      case 'preschool':
        return FilterOptionType.preschool;
      case 'other':
        return FilterOptionType.other;
      case 'grade':
        return FilterOptionType.regular;
    }
    final name = '${m['name'] ?? ''}'.trim().toLowerCase();
    if (name.startsWith('мектепке дейінгі')) return FilterOptionType.preschool;
    if (name.startsWith('басқа')) return FilterOptionType.other;
    return FilterOptionType.regular;
  }

  @override
  Future<List<FilterOption>> subjects({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  }) async => (await _filters(query, filters))['subjects']!;

  @override
  Future<List<FilterOption>> directions({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  }) async => (await _filters(query, filters))['directions']!;

  @override
  Future<List<FilterOption>> grades({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  }) async => (await _filters(query, filters))['classes']!;

  @override
  Future<int> count({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  }) async => (await search(query: query, filters: filters)).total;

  /// Бөлек endpoint жоқ: сәйкес пәндер + алғашқы материал атаулары
  @override
  Future<List<SearchSuggestion>> suggestions(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = await Future.wait([
      subjects(),
      search(query: query.trim()),
    ]);
    final subjectList = results[0] as List<FilterOption>;
    final page = results[1] as MaterialsPage;
    return [
      for (final s
          in subjectList.where((s) => s.name.toLowerCase().contains(q)).take(3))
        SearchSuggestion(text: s.name, tag: 'Пән'),
      for (final m in page.items.take(5))
        SearchSuggestion(text: m.title, tag: 'ҚМЖ / Сабақ'),
    ];
  }

  /// Backend `/mobile/materials/popular-queries` берсе — соны, әйтпесе
  /// мұғалімдер жиі іздейтін сұраулар (әрқайсысы api.ust.kz-те сай нәтиже береді).
  static const _defaultPopular = [
    'ҚМЖ',
    'Тәрбие сағаты',
    'Презентация',
    'БЖБ',
    'ТЖБ',
    'Ағылшын тілі',
    'Баяндама',
    'Олимпиада',
  ];

  @override
  Future<List<String>> popularQueries() async {
    const path = '/mobile/materials/popular-queries';
    if (!_isMissing(path)) {
      try {
        final res = await _dio.get(path);
        final items = [
          for (final q in (res.data['items'] as List? ?? const [])) '$q',
        ];
        if (items.isNotEmpty) return items;
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) return _defaultPopular;
        _missingAt[path] = DateTime.now();
      }
    }
    return _defaultPopular;
  }

  /// Ең көп материалы бар пәндер (сандар болмаса — алғашқы 6 пән)
  @override
  Future<List<MaterialCategory>> categories() async {
    final list = [...await subjects()]
      ..sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));
    return [
      for (final s in list.take(6))
        MaterialCategory(
          subjectId: s.id,
          name: s.name,
          countLabel: s.count == null
              ? ''
              : '${formatCount(s.count!)} материал',
        ),
    ];
  }

  // ---- Материал беті ----

  @override
  Future<MaterialDetail> detail(int id) async {
    final slug = _slugs[id];
    if (slug == null) throw const AppException('Материалды ашу мүмкін болмады');
    final res = await _dio.get('/word/$slug-$id');
    final d = res.data as Map<String, dynamic>;
    // Табылмаса backend 200 + {"status": 404} қайтарады
    if (_int(d['status']) == 404 || d['material'] == null) {
      throw const AppException('Материал табылмады');
    }
    final m = d['material'] as Map<String, dynamic>;
    final material = _material(m);
    if (m['filename'] != null) _fileNames[id] = '${m['filename']}';
    final fileUrl = m['file_doc'] == null
        ? null
        : _storageUrl('${m['file_doc']}');
    final savehtml = m['savehtml'];
    final isHtml =
        savehtml is Map &&
        savehtml['is_url'] != true &&
        savehtml['is_url'] != 1 &&
        savehtml['text'] is String &&
        (savehtml['text'] as String).trim().isNotEmpty;
    return MaterialDetail(
      material: material,
      fullDescription: '${m['description'] ?? ''}',
      direction: _str(m['zhanr2']) ?? '—',
      date: '${m['date'] ?? ''}',
      downloads: _int(m['download']),
      views: _int(m['view']),
      fileSize: _fileSize(await _contentLength(fileUrl)),
      // HTML — браузерде (previewHtml), беттердің суреттері — DocImage
      document: isHtml ? const [] : _preview(savehtml),
      previewHtml: isHtml ? savehtml['text'] as String : null,
      // uqsas_count = ұқсастар саны + 1
      similarCount: (_int(d['uqsas_count']) - 1).clamp(0, 999),
      isSaved: d['isSaved'] == true,
      pageCount: _int(m['page_count']) > 0 ? _int(m['page_count']) : null,
      fileUrl: fileUrl,
    );
  }

  /// `savehtml`: is_url болса — [беттердің суреттері, беттердің мәтіндері],
  /// әйтпесе — құжаттың HTML мәтіні.
  List<DocBlock> _preview(Object? savehtml) {
    if (savehtml is! Map) return const [];
    final text = savehtml['text'];
    if (savehtml['is_url'] == true || savehtml['is_url'] == 1) {
      final pages = text is List && text.isNotEmpty ? text[0] : null;
      return [
        for (final p in (pages as List? ?? const []))
          DocImage(_storageUrl('$p')),
      ];
    }
    return htmlToBlocks(text is String ? text : null, imageUrl: _storageUrl);
  }

  /// Файл көлемі: backend жібермейді, файлдың өзінен (HEAD) аламыз
  Future<int> _contentLength(String? url) async {
    if (url == null) return 0;
    try {
      final res = await Dio().head(url);
      return int.tryParse(res.headers.value('content-length') ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<List<StudyMaterial>> similar(int id, {int limit = 5}) async {
    final res = await _dio.get('/word/showOthers', queryParameters: {'id': id});
    return _materials(res.data['others']).take(limit).toList();
  }

  /// Материал жазылымы — үш нұсқа (`qauimdastyq_subs`):
  ///  - day   — «1 күндік» тарифі (id = 1);
  ///  - month — «Материал» тарифінің айлығы (id = 6, price_month);
  ///  - year  — «Материал» тарифінің жылдығы (id = 6, price_years).
  /// (тариф id, баға өрісі, атауы, сипаттамасы, мерзімі)
  static const _plans = {
    'day': (
      '1',
      'price_month',
      '1 күндік тариф',
      'Бүгін қажет материалдарды жүктеп алыңыз',
      '/ 1 күнге',
    ),
    'month': (
      '6',
      'price_month',
      'Айлық тариф',
      '30 күн бойы барлық материалдарға толық қолжетімділік',
      '/ 30 күн',
    ),
    'year': (
      '6',
      'price_years',
      'Жылдық тариф',
      'Бір жыл бойы барлық материалдарға толық қолжетімділік',
      '/ 365 күн',
    ),
  };

  /// Жылдық тарифтегі жеңілдіктің соңғы күні (backend бермейді)
  static const _discountUntil = '10.12.2026';

  @override
  Future<List<Tariff>> tariffs() async {
    final res = await _dio.get('/word/tarifter');
    final subs = {
      for (final t in (res.data['qauimdastyq'] as List? ?? const []))
        if (_int(t['status']) == 1) '${t['id']}': t as Map,
    };
    return [
      for (final e in _plans.entries)
        if (subs[e.value.$1] case final t?)
          Tariff(
            id: e.key,
            title: e.value.$3,
            subtitle: e.value.$4,
            price: _int(t[e.value.$2]),
            period: e.value.$5,
            best: e.key == 'year',
            // Жылдықта — 12 айдың бағасы сызылып тұрады және жеңілдік ескертуі
            oldPrice: e.key == 'year' ? _int(t['price_month']) * 12 : null,
            note: e.key == 'year'
                ? 'Арнайы жеңілдік $_discountUntil дейін жарамды. '
                      'Кейін жылдық тариф '
                      '${formatNumber(_int(t['price_month']) * 12)} ₸ болады.'
                : null,
          ),
    ];
  }

  /// Балансынан төленеді. Алдымен мобильді endpoint (айлық жазылымды тек ол
  /// сатады — сайтта «Материал» тарифі тек жылдық), ол әлі жоқ болса — сайттың
  /// `/word/tarifter/buy` (күндік пен жылдық үшін). Баланс жетпесе — хабар.
  @override
  Future<bool> buy(String tariffId) async {
    const mobile = '/mobile/tariffs/buy';
    Response<dynamic>? res;
    if (!_isMissing(mobile)) {
      try {
        res = await _dio.post(mobile, data: {'plan': tariffId});
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        _missingAt[mobile] = DateTime.now();
      }
    }
    if (res == null) {
      final plan = _plans[tariffId];
      // Сайттың endpoint-і «Материал» тарифін айлық бағамен сатпайды —
      // жылдық баға алынып кетпеуі үшін сатпаймыз
      if (plan == null || tariffId == 'month') {
        throw const AppException(
          'Айлық тариф әзірге қолжетімсіз. Күндік немесе жылдық тарифті таңдаңыз',
        );
      }
      res = await _dio.post(
        '/word/tarifter/buy',
        data: {'tarif_id': plan.$1, 'active_year': tariffId == 'year'},
      );
    }
    if (res.data is Map && res.data['status'] == false) {
      // Баға: backend берсе — сол, әйтпесе тарифтер тізіміндегі
      final price = _int(res.data['price']) > 0
          ? _int(res.data['price'])
          : (await tariffs())
                .where((t) => t.id == tariffId)
                .map((t) => t.price)
                .firstOrNull;
      final message =
          _str(res.data['message']) ?? 'Балансыңызда қаражат жеткіліксіз';
      if (price != null && price > 0) {
        throw InsufficientBalanceException(message, price: price);
      }
      throw AppException(message);
    }
    return true;
  }

  @override
  Future<String> downloadFile(int id) async {
    // «Офлайн сақтау» өшірулі болса — уақытша қалтаға (жүйе өзі тазалайды)
    final offline =
        (await SharedPreferences.getInstance()).getBool(offlineSaveKey) ?? true;
    final root = offline
        ? await getApplicationDocumentsDirectory()
        : await getTemporaryDirectory();
    final dir = Directory('${root.path}/materials');
    await dir.create(recursive: true);
    late String path;
    try {
      await _dio.download('/word/$id/download', (Headers headers) {
        final name =
            _fileNames[id] ?? _fileName(headers.value('content-disposition'));
        path = '${dir.path}/${name ?? 'material_$id'}';
        return path;
      }, options: Options(receiveTimeout: const Duration(minutes: 5)));
    } on DioException catch (e) {
      // 403 — тариф жоқ немесе күндік лимит бітті
      if (e.response?.statusCode == 403) {
        throw NoAccessException(errorMessage(e));
      }
      rethrow;
    }
    return path;
  }

  @override
  Future<void> report(int id, String text) {
    final user = _currentUser();
    return _dio.post(
      '/word/$id/report',
      data: {
        'id': id,
        'name': user?.name,
        'phone': user?.phone,
        'message': text,
      },
    );
  }

  /// Бір материал бір рет бағаланады: бұрын бағалаған болса backend 409
  /// қайтарады — қате емес, жай өтеміз. Endpoint әлі жоқ болса (404) — да.
  @override
  Future<void> rate(int id, int stars, String comment) async {
    try {
      await _dio.post(
        '/mobile/materials/$id/rate',
        data: {'stars': stars, if (comment.isNotEmpty) 'comment': comment},
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code != 404 && code != 409) rethrow;
    }
  }

  /// Endpoint жоқ немесе қате болса — бағаламаған деп есептейміз
  @override
  Future<bool> isRated(int id) async {
    try {
      final res = await _dio.get('/mobile/materials/$id/rating');
      return res.data['rated'] == true;
    } on DioException {
      return false;
    }
  }

  @override
  Future<bool> toggleSave(int id) async {
    final res = await _dio.post('/menin-materialdarym/$id/postSave');
    return res.data['isSaved'] == true;
  }

  // ---- Материалдарым ----

  /// Жаңа `/mobile/my/...` (файл түрі мен пәні бар), ол жоқ болса — сайттың
  /// `/menin-materialdarym?filter=` (2 — жүктелгендер, 1 — сақталғандар). Бәрін аламыз.
  Future<List<StudyMaterial>> _my(String mobilePath, int filter) async {
    final items = <StudyMaterial>[];
    for (var page = 1; page <= 20; page++) {
      final res = await _get(mobilePath, '/menin-materialdarym', {
        'filter': filter,
        'page': page,
      });
      // sendResponse — { success, data: {...} } немесе тікелей
      final body = res.data['data'] ?? res.data;
      final p = body['materials'] as Map<String, dynamic>;
      items.addAll(_materials(p['data']));
      if (_int(p['current_page']) >= _int(p['last_page'])) break;
    }
    return items;
  }

  @override
  Future<List<StudyMaterial>> downloadedMaterials() =>
      _my('/mobile/my/downloaded', 2);

  @override
  Future<List<StudyMaterial>> savedMaterials() => _my('/mobile/my/saved', 1);

  // ---- JSON көмекшілері ----

  static int _int(Object? v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;

  static String? _str(Object? v) {
    final s = v?.toString().trim();
    return s == null || s.isEmpty ? null : s;
  }

  /// Сайттағы файлдар: {backend}/storage/files/{жол}
  static String _storageUrl(String path) {
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return clean.startsWith('http') ? clean : '$base/storage/files/$clean';
  }

  StudyMaterial _material(Map<String, dynamic> m) {
    final id = _int(m['id']);
    final slug = _str(m['lat_title']);
    if (slug != null) _slugs[id] = slug;
    // raw жоқ болса — файл жолының кеңейтуі (materials/pdf/files/x.pdf)
    final raw =
        _str(m['raw']) ??
        RegExp(r'\.(\w+)$').firstMatch('${m['file_doc'] ?? ''}')?.group(1) ??
        'doc';
    return StudyMaterial(
      id: id,
      title: '${m['title'] ?? ''}',
      description: '${m['description'] ?? ''}',
      fileType: raw.toLowerCase(),
      grade: _str(m['zhanr3']),
      subject: _str(m['zhanr']),
      slug: slug,
    );
  }

  List<StudyMaterial> _materials(Object? list) => [
    for (final m in (list as List? ?? const []))
      _material(m as Map<String, dynamic>),
  ];

  /// 1887436 → «1.8 MB»
  static String _fileSize(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// `attachment; filename="abc.docx"` → abc.docx
  static String? _fileName(String? disposition) {
    if (disposition == null) return null;
    final utf = RegExp(r"filename\*=UTF-8''([^;]+)").firstMatch(disposition);
    if (utf != null) return Uri.decodeComponent(utf.group(1)!);
    final plain = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return plain?.group(1);
  }
}

/// 14200 → «14,200+»
String formatCount(int n) {
  if (n < 1000) return '$n';
  final s = (n ~/ 100 * 100).toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '$b+';
}

/// Құжаттың HTML алдын ала көрінісін бөліктерге бөледі
/// (тақырып, нөмірлі бөлім, мәтін, сурет). [imageUrl] — суреттің толық адресі.
List<DocBlock> htmlToBlocks(
  String? html, {
  String Function(String src)? imageUrl,
}) {
  if (html == null || html.trim().isEmpty) return const [];
  final clean = html
      .replaceAll(
        RegExp(
          r'<(script|style)[^>]*>.*?</\1>',
          dotAll: true,
          caseSensitive: false,
        ),
        '',
      )
      // Сурет — өз жолында, белгімен
      .replaceAllMapped(
        RegExp(
          r'''<img\b[^>]*\bsrc=["']([^"']+)["'][^>]*>''',
          caseSensitive: false,
        ),
        (m) => '\n\u0002${m.group(1)}\n',
      )
      // Блок тегтерінің соңы — жаңа жол
      .replaceAllMapped(
        RegExp(r'</(p|div|li|tr|h[1-6])>|<br\s*/?>', caseSensitive: false),
        (m) =>
            m.group(1)?.startsWith(RegExp('[hH]')) == true ? '\u0001\n' : '\n',
      );
  final blocks = <DocBlock>[];
  for (final raw in clean.split('\n')) {
    if (raw.startsWith('\u0002')) {
      final src = raw.substring(1).trim();
      if (src.isNotEmpty && !src.startsWith('data:')) {
        blocks.add(DocImage(imageUrl == null ? src : imageUrl(src)));
      }
      continue;
    }
    final heading = raw.contains('\u0001');
    final text = _decodeEntities(raw.replaceAll(RegExp(r'<[^>]+>'), ''))
        .replaceAll('\u0001', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) continue;
    final section = RegExp(r'^(\d{1,2})\.\s*(.+)$').firstMatch(text);
    if (section != null && text.length < 120) {
      blocks.add(DocSection(int.parse(section.group(1)!), section.group(2)!));
    } else if (heading) {
      blocks.add(DocHeading(text));
    } else {
      blocks.add(DocParagraph(text));
    }
  }
  return blocks;
}

String _decodeEntities(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&laquo;', '«')
    .replaceAll('&raquo;', '»')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&')
    .replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!)),
    );
