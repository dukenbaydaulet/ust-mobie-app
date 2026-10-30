import 'material.dart';
import 'material_detail.dart';
import 'materials_repository.dart';

/// Сынақ деректері. Әр материалдың пәні, бағыты және сыныбы бар,
/// сүзгілер мен сандар осы тізімнен шынайы есептеледі:
/// бірнеше сүзгі таңдалса — бәріне бірдей сай келетіндері ғана шығады.
class MockMaterialsRepository implements MaterialsRepository {
  MockMaterialsRepository() : _pool = _buildPool();

  static const _delay = Duration(milliseconds: 400);

  final List<_Item> _pool;

  static const _subjects = [
    ('algebra', 'Алгебра'),
    ('math', 'Математика'),
    ('physics', 'Физика'),
    ('society', 'Адам және қоғам'),
    ('military', 'Алғашқы әскери дайындық'),
    ('astronomy', 'Астрономия'),
    ('attestation', 'Аттестаттау материалдары'),
    ('social_ped', 'Әлеуметтік педагог'),
    ('sociology', 'Әлеуметтану'),
    ('method_lead', 'Әдістемелік бірлестік жетекшілері'),
    ('kindergarten', 'Балабақша'),
    ('primary', 'Бастауыш сынып'),
    ('kazakh', 'Қазақ тілі'),
    ('kazakh_lit', 'Қазақ әдебиеті'),
    ('history', 'Қазақстан тарихы'),
    ('visual', 'Көрнекілік'),
    ('upbringing', 'Тәрбие сағаты'),
    ('english', 'Ағылшын тілі'),
  ];

  static const _directions = [
    ('article', 'Мақала'),
    ('open_lesson', 'Ашық сабақ'),
    ('presentation', 'Презентация'),
    ('lesson_plan', 'Сабақ жоспары'),
    ('test', 'Тест'),
    ('upbringing_hour', 'Тәрбие сағаты'),
    ('seminar', 'Семинарлар'),
    ('outline', 'Конспект'),
    ('research', 'Ғылыми жұмыстар'),
    ('olympiad', 'Олимпиада тапсырмалары'),
  ];

  static final _grades = [
    ('preschool', 'Мектепке дейінгі білім беру'),
    for (var i = 1; i <= 12; i++) ('$i', '$i сынып'),
    ('other', 'Басқа санаттар (Колледж, әдіскерлер)'),
  ];

  /// Пән бойынша тақырыптар
  static const _topics = {
    'algebra': ['Квадрат теңдеулер', 'Функция және оның графигі', 'Көпмүшелер'],
    'math': [
      'Жай бөлшектерді қосу және азайту',
      'Пропорция',
      'Периметр және аудан',
    ],
    'physics': ['Ньютонның екінші заңы', 'Электр тогы', 'Жарықтың сынуы'],
    'kazakh_lit': [
      '«Қобыланды батыр» жыры',
      'Абай өлеңдері',
      'Ыбырай әңгімелері',
    ],
    'kazakh': ['Сөз таптары', 'Етістік', 'Сын есім'],
    'history': [
      'Алтын Орда дәуірі',
      'Қазақ хандығының құрылуы',
      'Тәуелсіздік жылдары',
    ],
    'upbringing': [
      '«Тәуелсіздік — тұғырым»',
      'Отбасы — бақыт мекені',
      'Жол ережесі',
    ],
    'english': ['Present Perfect Tense', 'My Family', 'Seasons and Weather'],
  };

  /// Бағыт бойынша файл түрі
  static const _fileTypes = {
    'presentation': ['pptx', 'ppt'],
    'lesson_plan': ['docx', 'doc'],
    'open_lesson': ['docx', 'pptx'],
    'test': ['pdf', 'docx'],
    'article': ['docx', 'pdf'],
    'research': ['pdf', 'rar'],
    'olympiad': ['pdf', 'zip'],
  };

  static const _descriptions = [
    'Балаларды отансүйгіштікке тәрбиелеу және қысқаша тарихына шолу жасай келе, тақырыптың ерекшеліктерін таныту.',
    'Оқушылардың тақырып бойынша білімін бекіту, логикалық ойлауын дамыту және өзіндік жұмысқа баулу.',
    'Сабақ барысында топтық жұмыс, сергіту сәті және бағалау парағы қолданылады.',
  ];

  /// Қысқартулар іздеуде табылуы үшін
  static const _aliases = {
    'lesson_plan': 'қмж ұмж сабақ жоспары',
    'test': 'тжб бжб тест',
    'open_lesson': 'ашық сабақ',
    'attestation': 'аттестаттау портфолио',
    'olympiad': 'олимпиада',
  };

  static List<_Item> _buildPool() {
    final items = <_Item>[];
    var id = 1;
    // Әр (пән × бағыт) жұбына бірнеше сыныпқа материалдар
    for (var s = 0; s < _subjects.length; s++) {
      for (var d = 0; d < _directions.length; d++) {
        final count = 1 + (s * 7 + d * 3) % 4;
        for (var k = 0; k < count; k++) {
          final grade = _grades[(s * 5 + d * 2 + k * 3) % _grades.length];
          final (subjectId, subject) = _subjects[s];
          final (directionId, direction) = _directions[d];
          final topics =
              _topics[subjectId] ??
              const ['Сабақ жоспары', 'Әдістемелік нұсқаулық'];
          final topic = topics[(k + d) % topics.length];
          final types = _fileTypes[directionId] ?? const ['docx', 'pdf'];
          final gradeLabel = int.tryParse(grade.$1) != null
              ? '${grade.$1}-сынып'
              : null;
          final title = [?gradeLabel, subject, topic].join('. ');
          final material = StudyMaterial(
            id: id++,
            title: title,
            description: _descriptions[(s + d + k) % _descriptions.length],
            fileType: types[k % types.length],
            grade: gradeLabel ?? grade.$2,
            subject: subject,
          );
          final haystack = [
            title,
            subject,
            direction,
            grade.$2,
            ?gradeLabel,
            _aliases[directionId] ?? '',
            _aliases[subjectId] ?? '',
          ].join(' ').toLowerCase();
          items.add(
            _Item(material, subjectId, directionId, grade.$1, haystack),
          );
        }
      }
    }
    // Тізім бір пәннен басталып кетпеуі үшін тұрақты ретпен араластырамыз
    items.sort(
      (a, b) => ((a.material.id * 7919) % 1009).compareTo(
        (b.material.id * 7919) % 1009,
      ),
    );
    return items;
  }

  /// Сұраудағы сөздер: әр сөз (немесе оның түбірі) материалда болуы керек.
  /// Ешбір материалда кездеспейтін сөздер (мыс. «2024») ескерілмейді,
  /// бірақ бірде-бір сөз танылмаса — нәтиже жоқ.
  bool Function(_Item) _queryMatcher(String query) {
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'[\s,.;:–—-]+'))
        .where((t) => t.isNotEmpty)
        .map((t) => t.length > 5 ? t.substring(0, 5) : t)
        .toList();
    if (tokens.isEmpty) return (_) => true;
    final known = tokens
        .where((t) => _pool.any((i) => i.haystack.contains(t)))
        .toList();
    if (known.isEmpty) return (_) => false;
    return (i) => known.every(i.haystack.contains);
  }

  bool _matchesFilters(_Item i, MaterialFilters f, {FilterKindKey? except}) =>
      (except == FilterKindKey.subjects ||
          f.subjects.isEmpty ||
          f.subjects.contains(i.subjectId)) &&
      (except == FilterKindKey.directions ||
          f.directions.isEmpty ||
          f.directions.contains(i.directionId)) &&
      (except == FilterKindKey.grades ||
          f.grades.isEmpty ||
          f.grades.contains(i.gradeId));

  List<_Item> _filter(String query, MaterialFilters filters) {
    final matchQuery = _queryMatcher(query);
    return _pool
        .where((i) => matchQuery(i) && _matchesFilters(i, filters))
        .toList();
  }

  @override
  Future<MaterialsPage> search({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
    int offset = 0,
    int limit = 10,
  }) async {
    await Future<void>.delayed(_delay);
    final all = _filter(query, filters);
    final start = offset.clamp(0, all.length);
    final end = (start + limit).clamp(0, all.length);
    return MaterialsPage(
      items: [for (final i in all.sublist(start, end)) i.material],
      total: all.length,
      hasMore: end < all.length,
    );
  }

  /// Нұсқалар саны басқа таңдалған сүзгілерді ескереді
  /// (мысалы, 5-сынып таңдалса, пәндер жанында 5-сыныптағы сан тұрады).
  List<FilterOption> _options(
    List<(String, String)> all,
    String Function(_Item) key,
    FilterKindKey kind,
    String query,
    MaterialFilters filters,
  ) {
    final matchQuery = _queryMatcher(query);
    final counts = <String, int>{};
    for (final i in _pool.where(
      (i) => matchQuery(i) && _matchesFilters(i, filters, except: kind),
    )) {
      counts[key(i)] = (counts[key(i)] ?? 0) + 1;
    }
    return [
      for (final (id, name) in all)
        FilterOption(
          id: id,
          name: name,
          count: counts[id] ?? 0,
          type: switch (id) {
            'preschool' => FilterOptionType.preschool,
            'other' => FilterOptionType.other,
            _ => FilterOptionType.regular,
          },
        ),
    ];
  }

  @override
  Future<List<FilterOption>> subjects({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  }) async => _options(
    _subjects,
    (i) => i.subjectId,
    FilterKindKey.subjects,
    query,
    filters,
  );

  @override
  Future<List<FilterOption>> directions({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  }) async => _options(
    _directions,
    (i) => i.directionId,
    FilterKindKey.directions,
    query,
    filters,
  );

  @override
  Future<List<FilterOption>> grades({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  }) async =>
      _options(_grades, (i) => i.gradeId, FilterKindKey.grades, query, filters);

  @override
  Future<int> count({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  }) async => _filter(query, filters).length;

  @override
  Future<List<SearchSuggestion>> suggestions(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    const all = [
      SearchSuggestion(
        text: 'математика 5 сынып',
        tag: 'Пән',
        fromHistory: true,
      ),
      SearchSuggestion(text: 'математикалық сауаттылық', tag: 'Курс / Бағыт'),
      SearchSuggestion(text: 'математика ашық сабақ ҚМЖ', tag: 'ҚМЖ / Сабақ'),
      SearchSuggestion(text: 'математикадан олимпиада', tag: 'Олимпиада'),
      SearchSuggestion(text: 'математика пәні мұғалімдері', tag: 'Әдістеме'),
      SearchSuggestion(text: 'қазақ тілі ҚМЖ', tag: 'ҚМЖ / Сабақ'),
      SearchSuggestion(text: 'қазақ әдебиеті 6 сынып', tag: 'Пән'),
      SearchSuggestion(text: 'тәрбие сағаты тәуелсіздік', tag: 'Тәрбие'),
      SearchSuggestion(text: 'алгебра ТЖБ жауаптарымен', tag: 'ТЖБ / БЖБ'),
      SearchSuggestion(text: 'физика зертханалық жұмыс', tag: 'Пән'),
    ];
    return all
        .where((s) => s.text.toLowerCase().startsWith(q))
        .take(5)
        .toList();
  }

  @override
  Future<List<String>> popularQueries() async => const [
    'ҚМЖ 2024–2025',
    'Математика 5 сынып',
    'Ашық сабақ',
    'ҰБТ дайындық',
    'Презентация үлгісі',
    'ТЖБ мен БЖБ',
    'Бастауыш сынып',
    'Ағылшын тілі flashcards',
  ];

  @override
  Future<List<MaterialCategory>> categories() async {
    final subjects = await this.subjects();
    String label(String id, String unit) {
      final n = subjects.firstWhere((s) => s.id == id).count;
      return '$n $unit';
    }

    return [
      MaterialCategory(
        subjectId: 'primary',
        name: 'Бастауыш сынып',
        countLabel: label('primary', 'материал'),
      ),
      MaterialCategory(
        subjectId: 'math',
        name: 'Математика',
        countLabel: label('math', 'материал'),
      ),
      MaterialCategory(
        subjectId: 'kazakh',
        name: 'Қазақ тілі',
        countLabel: label('kazakh', 'материал'),
      ),
      MaterialCategory(
        subjectId: 'history',
        name: 'Қазақстан тарихы',
        countLabel: label('history', 'материал'),
      ),
      MaterialCategory(
        subjectId: 'visual',
        name: 'Көрнекілік',
        countLabel: label('visual', 'файл'),
      ),
      MaterialCategory(
        subjectId: 'upbringing',
        name: 'Тәрбие сағаты',
        countLabel: label('upbringing', 'үлгі'),
      ),
    ];
  }

  // ---- Материал беті ----

  _Item _byId(int id) => _pool.firstWhere((i) => i.material.id == id);

  @override
  Future<MaterialDetail> detail(int id) async {
    await Future<void>.delayed(_delay);
    final item = _byId(id);
    final m = item.material;
    final direction = _directions
        .firstWhere((d) => d.$1 == item.directionId)
        .$2;
    final similar = _pool.where(
      (i) => i.subjectId == item.subjectId && i.material.id != id,
    );
    return MaterialDetail(
      material: m,
      fullDescription:
          '${m.description} Материал жаңартылған білім беру бағдарламасына сай '
          'әзірленген. Ішінде сабақтың мақсаттары, барысы, тапсырмалар, '
          'дескрипторлар және бағалау критерийлері берілген. Мұғалімдер оны '
          'сабаққа дайындалу кезінде өзгертіп, толықтыра алады.',
      direction: direction,
      date: '${10 + id % 18} ақпан 2025',
      downloads: 10 + id * 7 % 90,
      views: 100 + id * 13 % 900,
      fileSize: '${1 + id % 4}.${id % 10} MB',
      document: _document(m, direction),
      similarCount: similar.length,
    );
  }

  /// Сынақ құжаты: бір тұтас сабақ жоспары (беттерге бөлінбейді)
  List<DocBlock> _document(StudyMaterial m, String direction) {
    const lorem =
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do '
        'eiusmod tempor incididunt ut labore et dolore magna aliqua. Quis ipsum '
        'suspendisse ultrices gravida. Risus commodo viverra maecenas accumsan '
        'lacus vel facilisis.';
    return [
      const DocHeading(
        'ҚАЗАҚСТАН РЕСПУБЛИКАСЫ БІЛІМ ЖӘНЕ ҒЫЛЫМ МИНИСТРЛІГІ\n'
        '№12 жалпы білім беретін мектеп',
      ),
      DocHeading('Қысқа мерзімді жоспар ($direction)'),
      DocFields([
        ('Пән', m.subject ?? '—'),
        ('Сынып', m.grade ?? '—'),
        ('Күні', '18.02.2025'),
        ('Мұғалім', 'Айгүл Серікқызы'),
      ]),
      const DocSection(1, 'Сабақтың тақырыбы:'),
      DocParagraph(m.title),
      const DocSection(2, 'Оқу мақсаттары (Оқу бағдарламасына сілтеме):'),
      const DocParagraph(lorem),
      for (var s = 3; s <= 10; s++) ...[
        DocSection(s, switch (s % 4) {
          0 => 'Сабақтың мақсаты:',
          1 => 'Сабақтың барысы:',
          2 => 'Бағалау критерийлері:',
          _ => 'Дескрипторлар:',
        }),
        const DocParagraph(lorem),
        const DocParagraph(lorem),
      ],
    ];
  }

  // Сынақта: пулдан әр түрлі пәндегі материалдар
  @override
  Future<List<StudyMaterial>> downloadedMaterials() async {
    await Future<void>.delayed(_delay);
    return [for (var i = 0; i < _pool.length; i += 7) _pool[i].material]
        .take(18)
        .toList();
  }

  @override
  Future<List<StudyMaterial>> savedMaterials() async {
    await Future<void>.delayed(_delay);
    return [for (var i = 3; i < _pool.length; i += 5) _pool[i].material]
        .take(34)
        .toList();
  }

  @override
  Future<List<StudyMaterial>> similar(int id, {int limit = 5}) async {
    await Future<void>.delayed(_delay);
    final item = _byId(id);
    return _pool
        .where((i) => i.subjectId == item.subjectId && i.material.id != id)
        .take(limit)
        .map((i) => i.material)
        .toList();
  }

  // Сынақта: жазылым жоқ, тариф сатып алынғаннан кейін пайда болады
  bool _subscribed = false;
  final _saved = <int>{};

  @override
  Future<List<Tariff>> tariffs() async => const [
    Tariff(
      id: 'day',
      title: '1 күндік тариф',
      subtitle: 'Бүгін қажет материалдарды жүктеп алыңыз',
      price: 790,
      period: '/ 1 күнге',
    ),
    Tariff(
      id: 'month',
      title: 'Айлық тариф',
      subtitle: '30 күн бойы барлық материалдарға толық қолжетімділік',
      price: 2990,
      period: '/ 30 күн',
    ),
    Tariff(
      id: 'year',
      title: 'Жылдық тариф',
      subtitle: 'Бір жыл бойы барлық материалдарға толық қолжетімділік',
      price: 4990,
      period: '/ 365 күн',
      oldPrice: 35880,
      best: true,
      note:
          'Арнайы жеңілдік 25.09.2026 дейін жарамды. '
          'Кейін жылдық тариф 35 880 ₸ болады.',
    ),
  ];

  @override
  Future<bool> buy(String tariffId) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _subscribed = true;
    return true;
  }

  /// Сынақта файл жоқ — бос жол қайтарамыз (ашу қадамы өткізіледі)
  @override
  Future<String> downloadFile(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!_subscribed) throw const NoAccessException('Тариф жоқ');
    return '';
  }

  @override
  Future<bool> toggleSave(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _saved.add(id) || !_saved.remove(id);
  }

  @override
  Future<void> report(int id, String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> rate(int id, int stars, String comment) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _rated.add(id);
  }

  final _rated = <int>{};

  @override
  Future<bool> isRated(int id) async => _rated.contains(id);
}

enum FilterKindKey { subjects, directions, grades }

class _Item {
  const _Item(
    this.material,
    this.subjectId,
    this.directionId,
    this.gradeId,
    this.haystack,
  );
  final StudyMaterial material;
  final String subjectId;
  final String directionId;
  final String gradeId;

  /// Іздеу үшін барлық мәтін (кіші әріппен)
  final String haystack;
}
