import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../auth/auth_controller.dart';
import 'api_materials_repository.dart';
import 'material.dart';
import 'material_detail.dart';
import 'mock_materials_repository.dart';

/// Жүктеп алуға құқық жоқ (тариф жоқ немесе күндік лимит бітті).
class NoAccessException extends AppException {
  const NoAccessException(super.message);
}

/// Тариф сатып алуға балансы жетпейді — Kaspi арқылы толтыру керек.
class InsufficientBalanceException extends AppException {
  const InsufficientBalanceException(super.message, {required this.price});

  /// Толтыратын сома (тариф бағасы, ₸) — сайттағыдай
  final int price;
}

/// Материалдар деректерінің көзі.
/// [ApiMaterialsRepository] — backend (сайттың `/api/word/...` endpoint-тері),
/// [MockMaterialsRepository] — сынақ деректері (`--dart-define=MOCK_MATERIALS=true`).
abstract class MaterialsRepository {
  /// Материалдар тізімі. [query] бос болса — жалпы каталог.
  Future<MaterialsPage> search({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
    int offset = 0,
    int limit = 10,
  });

  /// Сүзгілер үшін нұсқалар. Сандар сұрауды және басқа таңдалған
  /// сүзгілерді ескереді (мыс. 5-сынып таңдалса — пәндер жанында 5-сыныптағы сан).
  Future<List<FilterOption>> subjects({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  });
  Future<List<FilterOption>> directions({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  });
  Future<List<FilterOption>> grades({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  });

  /// «Көрсету (N)» батырмасындағы сан.
  Future<int> count({
    String query = '',
    MaterialFilters filters = const MaterialFilters(),
  });

  /// Теру кезіндегі ұсыныстар.
  Future<List<SearchSuggestion>> suggestions(String query);

  /// Танымал сұраулар.
  Future<List<String>> popularQueries();

  /// Ұсынылатын санаттар.
  Future<List<MaterialCategory>> categories();

  // ---- Материал беті ----

  /// Материалдың толық деректері.
  Future<MaterialDetail> detail(int id);

  /// Ұқсас материалдар.
  Future<List<StudyMaterial>> similar(int id, {int limit = 5});

  /// Жазылым тарифтері.
  Future<List<Tariff>> tariffs();

  /// Тарифті сатып алу (төлем). Сәтті болса — true.
  Future<bool> buy(String tariffId);

  /// Файлды құрылғыға жүктеп, жергілікті жолын қайтарады.
  /// Құқық жоқ болса — [NoAccessException].
  Future<String> downloadFile(int id);

  /// Сақтау / сақтаудан алу. Жаңа күйін қайтарады (true — сақталды).
  Future<bool> toggleSave(int id);

  /// Шағым жіберу.
  Future<void> report(int id, String text);

  /// Баға (1–5) және пікір.
  Future<void> rate(int id, int stars, String comment);

  /// Пайдаланушы бұл материалды бағалаған ба (бір материал — бір баға).
  Future<bool> isRated(int id);

  // ---- Материалдарым ----

  /// Пайдаланушы жүктеген материалдар (соңғы жүктелгені бірінші).
  Future<List<StudyMaterial>> downloadedMaterials();

  /// Сақталған (бетбелгі) материалдар (соңғы сақталғаны бірінші).
  Future<List<StudyMaterial>> savedMaterials();
}

final materialsRepositoryProvider = Provider<MaterialsRepository>(
  (ref) => AppConfig.mockMaterials
      ? MockMaterialsRepository()
      : ApiMaterialsRepository(
          ref.read(dioProvider),
          () => ref.read(authProvider).value,
        ),
);
