import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import 'material.dart';
import 'materials_repository.dart';

/// Тізім сұрауы: іздеу мәтіні + сүзгілер.
typedef MaterialsQuery = ({String query, MaterialFilters filters});

class MaterialsListState {
  const MaterialsListState({
    this.items = const [],
    this.total = 0,
    this.hasMore = true,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<StudyMaterial> items;
  final int total;
  final bool hasMore;

  /// Бірінші бет жүктеліп жатыр
  final bool loading;

  /// Келесі бет жүктеліп жатыр
  final bool loadingMore;
  final String? error;

  MaterialsListState copyWith({
    List<StudyMaterial>? items,
    int? total,
    bool? hasMore,
    bool? loading,
    bool? loadingMore,
    String? error,
  }) {
    return MaterialsListState(
      items: items ?? this.items,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }
}

/// Беттеп жүктелетін материалдар тізімі.
final materialsListProvider = NotifierProvider.autoDispose
    .family<MaterialsList, MaterialsListState, MaterialsQuery>(
      MaterialsList.new,
    );

class MaterialsList extends Notifier<MaterialsListState> {
  MaterialsList(this.query);
  final MaterialsQuery query;

  /// Бет бірден ауыр болмауы үшін алдымен 10 материал,
  /// төмен түскен сайын тағы 5-тен қосылады.
  static const firstBatch = 10;
  static const nextBatch = 5;

  /// Жүріп жатқан сұраныс: қайта шақырылса, соны күтеміз (екі рет жүктелмейді)
  Future<void>? _inFlight;

  /// Бірінші бөлік жүктелді ме (нәтиже бос болса да)
  bool _started = false;

  /// refresh() кезінде ескі сұраныстың нәтижесін елемеу үшін
  int _generation = 0;

  MaterialsRepository get _repo => ref.read(materialsRepositoryProvider);

  @override
  MaterialsListState build() {
    Future.microtask(loadMore);
    return const MaterialsListState();
  }

  Future<void> refresh() async {
    _generation++;
    _inFlight = null;
    _started = false;
    state = const MaterialsListState();
    await loadMore();
  }

  Future<void> loadMore() {
    if (_inFlight != null) return _inFlight!;
    if (_started && !state.hasMore) return Future.value();
    late final Future<void> future;
    future = _load().whenComplete(() {
      // refresh() кейін басталған жаңа сұранысты өшіріп тастамаймыз
      if (identical(_inFlight, future)) _inFlight = null;
    });
    return _inFlight = future;
  }

  Future<void> _load() async {
    final first = !_started;
    final generation = _generation;
    if (!first) state = state.copyWith(loadingMore: true);
    try {
      final result = await _repo.search(
        query: query.query,
        filters: query.filters,
        offset: state.items.length,
        limit: first ? firstBatch : nextBatch,
      );
      if (!ref.mounted || generation != _generation) return;
      _started = true;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        total: result.total,
        hasMore: result.hasMore,
        loading: false,
        loadingMore: false,
      );
    } catch (e) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        error: errorMessage(e),
      );
    }
  }
}

/// Басты беттегі (каталогтағы) сүзгілер.
final catalogFiltersProvider =
    NotifierProvider<CatalogFilters, MaterialFilters>(CatalogFilters.new);

class CatalogFilters extends Notifier<MaterialFilters> {
  @override
  MaterialFilters build() => const MaterialFilters();

  void set(MaterialFilters filters) => state = filters;
  void clear() => state = const MaterialFilters();
}

final popularQueriesProvider = FutureProvider<List<String>>(
  (ref) => ref.read(materialsRepositoryProvider).popularQueries(),
);
final categoriesProvider = FutureProvider<List<MaterialCategory>>(
  (ref) => ref.read(materialsRepositoryProvider).categories(),
);

/// Соңғы іздеулер — телефонда сақталады.
final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(
  RecentSearches.new,
);

class RecentSearches extends Notifier<List<String>> {
  static const _key = 'recent_searches';
  static const _max = 10;

  // Дизайнды тексеру үшін debug-та бірінші іске қосқанда толтырамыз
  static const _demo = [
    '5-сынып Қазақ тілі ҚМЖ',
    'Алгебра 7-сынып ТЖБ жауаптарымен',
    'Тәрбие сағаты Тәуелсіздік күні',
    'Бастауыш математика ашық сабақ',
    'Аттестаттау портфолио үлгісі',
  ];

  late Future<void> _loaded;

  @override
  List<String> build() {
    _loaded = _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (!ref.mounted) return;
    state = saved ?? (kDebugMode ? _demo : const []);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  // Сақталған тізім жүктеліп болғаннан кейін ғана өзгертеміз
  Future<void> add(String query) async {
    await _loaded;
    final q = query.trim();
    if (q.isEmpty) return;
    state = [
      q,
      ...state.where((s) => s.toLowerCase() != q.toLowerCase()),
    ].take(_max).toList();
    _save();
  }

  void remove(String query) {
    state = state.where((s) => s != query).toList();
    _save();
  }

  void clear() {
    state = const [];
    _save();
  }
}
