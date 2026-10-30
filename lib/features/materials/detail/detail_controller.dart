import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../my_materials/my_materials_screen.dart';
import '../material.dart';
import '../material_detail.dart';
import '../materials_repository.dart';
import 'detail_sheets.dart';

/// Материалдың толық деректері. Сақталған белгісін де жаңартады.
final materialDetailProvider = FutureProvider.autoDispose
    .family<MaterialDetail, int>((ref, id) async {
      final d = await ref.read(materialsRepositoryProvider).detail(id);
      ref.read(savedMaterialsProvider.notifier).set(id, d.isSaved);
      return d;
    });

/// Ұқсас материалдар.
final similarMaterialsProvider = FutureProvider.autoDispose
    .family<List<StudyMaterial>, int>(
      (ref, id) => ref.read(materialsRepositoryProvider).similar(id),
    );

/// Сақталған (бетбелгі) материалдардың id-лері. Материал беті ашылғанда
/// backend-тегі күйі жазылады, басқанда backend-те ауыстырылады.
final savedMaterialsProvider = NotifierProvider<SavedMaterials, Set<int>>(
  SavedMaterials.new,
);

class SavedMaterials extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void set(int id, bool saved) {
    if (state.contains(id) == saved) return;
    state = saved ? {...state, id} : ({...state}..remove(id));
  }

  /// Backend-те ауыстырады. Жаңа күйін қайтарады (true — сақталды).
  /// Қате болса — бұрынғы күйі қалады және қате лақтырылады.
  Future<bool> toggle(int id) async {
    final before = state.contains(id);
    set(id, !before); // бірден көрінсін
    try {
      final saved = await ref.read(materialsRepositoryProvider).toggleSave(id);
      set(id, saved);
      ref.invalidate(savedMaterialsListProvider);
      return saved;
    } catch (_) {
      set(id, before);
      rethrow;
    }
  }
}

/// Кірген бе (қонақ емес пе).
bool isLoggedIn(WidgetRef ref) => ref.read(authProvider).value != null;

/// «Жүктеп алу»:
///  - қонақ → «Кабинетке кіру керек»;
///  - тариф жоқ / лимит бітті → тарифтер, сатып алса қайта жүктейді;
///  - әйтпесе → файлды қосымшаның ішінде жүктеп ашады, сосын бағалау терезесі.
Future<void> downloadMaterial(
  BuildContext context,
  WidgetRef ref,
  MaterialDetail d,
) async {
  if (!isLoggedIn(ref)) {
    await showLoginRequiredSheet(
      context,
      material: d.material,
      fileSize: d.fileSize,
    );
    return;
  }
  final repo = ref.read(materialsRepositoryProvider);
  void showError(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  String path;
  try {
    path = await repo.downloadFile(d.material.id);
  } on NoAccessException {
    if (!context.mounted) return;
    final bought = await showTariffDialog(context);
    if (!bought) return;
    try {
      path = await repo.downloadFile(d.material.id);
    } catch (e) {
      if (context.mounted) {
        showError(e is NoAccessException ? e.message : errorMessage(e));
      }
      return;
    }
  } catch (e) {
    if (context.mounted) showError(errorMessage(e));
    return;
  }

  ref.invalidate(downloadedMaterialsProvider);
  // Браузер ашылмайды: файл телефонда сақталып, сәйкес қолданбамен ашылады
  if (path.isNotEmpty) {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      showError('Файл сақталды, бірақ оны ашатын қолданба табылмады');
    }
  }
  // Бір материал бір рет бағаланады — бағалаған болса терезе ашылмайды
  if (await repo.isRated(d.material.id)) return;
  if (!context.mounted) return;
  await showRatingDialog(context, material: d.material, fileSize: d.fileSize);
}
