import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/typography.dart';
import 'materials_controller.dart';
import 'materials_list_view.dart';
import 'widgets/filter_sheets.dart';
import 'widgets/material_widgets.dart';

/// Басты бет: «Оқу әдістемелік материалдар».
class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(catalogFiltersProvider);

    Future<void> openFilter(FilterKind kind) async {
      final result = await showFilterSheet(
        context,
        kind: kind,
        initial: filters,
      );
      if (result != null) ref.read(catalogFiltersProvider.notifier).set(result);
    }

    return Scaffold(
      backgroundColor: MColors.page,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const LogoHeader(),
            Expanded(
              child: MaterialsListView(
                query: (query: '', filters: filters),
                endText: (_) => 'Барлық жаңа материалдар жүктелді',
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Text(
                        'Оқу әдістемелік материалдар',
                        style: AppText.pageTitle,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SearchBox(
                        readOnly: true,
                        onTap: () => context.push('/search'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilterBar(
                      filters: filters,
                      onSubjects: () => openFilter(FilterKind.subjects),
                      onDirections: () => openFilter(FilterKind.directions),
                      onGrades: () => openFilter(FilterKind.grades),
                      onClear: () =>
                          ref.read(catalogFiltersProvider.notifier).clear(),
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
}
