import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ust_mobile_app/features/materials/material.dart';
import 'package:ust_mobile_app/features/materials/materials_controller.dart';
import 'package:ust_mobile_app/features/materials/materials_repository.dart';
import 'package:ust_mobile_app/features/materials/mock_materials_repository.dart';

/// Сынақ деректерін орап, search() қалай шақырылғанын жазып алады.
class RecordingRepository extends MockMaterialsRepository {
  final calls = <({int offset, int limit})>[];

  @override
  Future<MaterialsPage> search({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
    int offset = 0,
    int limit = 10,
  }) {
    calls.add((offset: offset, limit: limit));
    return super.search(
      query: query,
      filters: filters,
      offset: offset,
      limit: limit,
    );
  }
}

void main() {
  group('Бөліктеп жүктеу (10, кейін 5-тен)', () {
    late RecordingRepository repo;
    late ProviderContainer container;
    const query = (query: '', filters: MaterialFilters());

    setUp(() {
      repo = RecordingRepository();
      container = ProviderContainer(
        overrides: [materialsRepositoryProvider.overrideWithValue(repo)],
      );
    });
    tearDown(() => container.dispose());

    Future<MaterialsListState> waitIdle() async {
      final provider = materialsListProvider(query);
      while (true) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final s = container.read(provider);
        if (!s.loading && !s.loadingMore) return s;
      }
    }

    test('алдымен 10 материал жүктеледі', () async {
      container.listen(materialsListProvider(query), (_, _) {});
      final s = await waitIdle();
      expect(s.items, hasLength(10));
      expect(repo.calls, [(offset: 0, limit: 10)]);
      expect(s.hasMore, isTrue);
    });

    test('әр loadMore 5 материал қосады', () async {
      container.listen(materialsListProvider(query), (_, _) {});
      await waitIdle();
      final notifier = container.read(materialsListProvider(query).notifier);

      await notifier.loadMore();
      expect(container.read(materialsListProvider(query)).items, hasLength(15));

      await notifier.loadMore();
      expect(container.read(materialsListProvider(query)).items, hasLength(20));

      expect(repo.calls, [
        (offset: 0, limit: 10),
        (offset: 10, limit: 5),
        (offset: 15, limit: 5),
      ]);
    });

    test('бір мезгілде екі рет шақырса, бір рет қана жүктеледі', () async {
      container.listen(materialsListProvider(query), (_, _) {});
      await waitIdle();
      final notifier = container.read(materialsListProvider(query).notifier);

      await Future.wait([
        notifier.loadMore(),
        notifier.loadMore(),
        notifier.loadMore(),
      ]);
      expect(container.read(materialsListProvider(query)).items, hasLength(15));
      expect(repo.calls, hasLength(2));
    });

    test('материалдар қайталанбайды және соңында тоқтайды', () async {
      // Аз нәтиже беретін сүзгі: соңына тез жетеміз
      const small = (
        query: '',
        filters: MaterialFilters(subjects: {'math'}, grades: {'5'}),
      );
      container.listen(materialsListProvider(small), (_, _) {});
      final notifier = container.read(materialsListProvider(small).notifier);
      final total = await repo.count(filters: small.filters);

      for (var i = 0; i < 50; i++) {
        await notifier.loadMore();
      }
      final s = container.read(materialsListProvider(small));
      expect(s.items, hasLength(total));
      expect(
        s.items.map((m) => m.id).toSet(),
        hasLength(total),
        reason: 'қайталанған материал бар',
      );
      expect(s.hasMore, isFalse);
      expect(s.total, total);
    });
  });

  group('Шеткі жағдайлар', () {
    late RecordingRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = RecordingRepository();
      container = ProviderContainer(
        overrides: [materialsRepositoryProvider.overrideWithValue(repo)],
      );
    });
    tearDown(() => container.dispose());

    test('нәтиже бос болса, айналдырған сайын қайта сұрамайды', () async {
      const empty = (query: 'asdfgh', filters: MaterialFilters());
      container.listen(materialsListProvider(empty), (_, _) {});
      final notifier = container.read(materialsListProvider(empty).notifier);
      for (var i = 0; i < 5; i++) {
        await notifier.loadMore();
      }
      final s = container.read(materialsListProvider(empty));
      expect(s.items, isEmpty);
      expect(s.loading, isFalse);
      expect(repo.calls, hasLength(1));
    });

    test('refresh() ескі сұраныстың нәтижесін қоспайды', () async {
      const q = (query: '', filters: MaterialFilters());
      container.listen(materialsListProvider(q), (_, _) {});
      final notifier = container.read(materialsListProvider(q).notifier);
      // Бірінші жүктеу әлі жүріп жатқанда жаңартамыз
      await Future<void>.delayed(Duration.zero);
      await notifier.refresh();
      final s = container.read(materialsListProvider(q));
      expect(s.items, hasLength(10));
      expect(s.items.map((m) => m.id).toSet(), hasLength(10));
    });
  });

  group('Сүзгілер (бәріне ортақтары ғана)', () {
    final repo = MockMaterialsRepository();

    Future<List<StudyMaterial>> all(
      MaterialFilters f, {
      String query = '',
    }) async {
      final total = await repo.count(query: query, filters: f);
      final page = await repo.search(query: query, filters: f, limit: total);
      return page.items;
    }

    test('пән + сынып: тек 5-сыныптың математикасы', () async {
      final items = await all(
        const MaterialFilters(subjects: {'math'}, grades: {'5'}),
      );
      expect(items, isNotEmpty);
      for (final m in items) {
        expect(m.subject, 'Математика');
        expect(m.grade, '5-сынып');
      }
    });

    test('сүзгі қосылған сайын нәтиже азаяды (немесе өзгермейді)', () async {
      final none = await repo.count();
      final subject = await repo.count(
        filters: const MaterialFilters(subjects: {'math'}),
      );
      final subjectGrade = await repo.count(
        filters: const MaterialFilters(subjects: {'math'}, grades: {'5'}),
      );
      final allThree = await repo.count(
        filters: const MaterialFilters(
          subjects: {'math'},
          grades: {'5'},
          directions: {'presentation'},
        ),
      );
      expect(subject, lessThanOrEqualTo(none));
      expect(subjectGrade, lessThanOrEqualTo(subject));
      expect(allThree, lessThanOrEqualTo(subjectGrade));
    });

    test('бір топ ішінде бірнеше нұсқа — НЕМЕСЕ (5 немесе 6 сынып)', () async {
      final five = await repo.count(
        filters: const MaterialFilters(grades: {'5'}),
      );
      final six = await repo.count(
        filters: const MaterialFilters(grades: {'6'}),
      );
      final both = await repo.count(
        filters: const MaterialFilters(grades: {'5', '6'}),
      );
      expect(both, five + six);
    });

    test('«Көрсету (N)» = тізімдегі «N материал табылды»', () async {
      const f = MaterialFilters(subjects: {'math', 'algebra'}, grades: {'7'});
      final count = await repo.count(filters: f);
      final page = await repo.search(filters: f);
      expect(page.total, count);
    });

    test('терезедегі пән саны = сол пәнді таңдағандағы нәтиже', () async {
      const grade5 = MaterialFilters(grades: {'5'});
      final subjects = await repo.subjects(filters: grade5);
      for (final s in subjects) {
        final real = await repo.count(
          filters: MaterialFilters(subjects: {s.id}, grades: {'5'}),
        );
        expect(s.count, real, reason: s.name);
      }
    });

    test('сұрау + сүзгі бірге: «математика» және 5-сынып', () async {
      final items = await all(
        const MaterialFilters(grades: {'5'}),
        query: 'математика',
      );
      expect(items, isNotEmpty);
      for (final m in items) {
        expect(m.grade, '5-сынып');
        expect(m.title.toLowerCase(), contains('математика'));
      }
    });

    test('мағынасыз сұрау — нәтиже жоқ', () async {
      expect(await repo.count(query: 'asdfgh'), 0);
    });
  });
}
