import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'materials_controller.dart';
import 'widgets/material_widgets.dart';

/// Материалдар тізімі: «N материал табылды», карточкалар, соңғы жазу.
/// Төменге жеткенде келесі бет өзі жүктеледі.
class MaterialsListView extends ConsumerStatefulWidget {
  const MaterialsListView({
    super.key,
    required this.query,
    required this.header,
    required this.endText,
    this.showScrollTop = false,
    this.empty,
  });

  final MaterialsQuery query;

  /// Тізімнің үстіндегі бөлік (тақырып, іздеу, сүзгілер)
  final Widget header;

  /// Тізім соңындағы жазу
  final String Function(int total) endText;
  final bool showScrollTop;

  /// Нәтиже жоқ кездегі бет
  final Widget? empty;

  @override
  ConsumerState<MaterialsListView> createState() => _MaterialsListViewState();
}

class _MaterialsListViewState extends ConsumerState<MaterialsListView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(materialsListProvider(widget.query).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = materialsListProvider(widget.query);
    final s = ref.watch(provider);
    final empty = !s.loading && s.error == null && s.items.isEmpty;

    return RefreshIndicator(
      onRefresh: () => ref.read(provider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: widget.header),
          if (empty && widget.empty != null)
            SliverToBoxAdapter(child: widget.empty)
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: s.loading
                    ? const SizedBox(height: 18)
                    : FoundCount(total: s.total),
              ),
            ),
            if (s.error != null && s.items.isEmpty)
              SliverToBoxAdapter(
                child: _ErrorBox(
                  onRetry: () => ref.read(provider.notifier).refresh(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: s.loading ? 4 : s.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => s.loading
                      ? const MaterialCardSkeleton()
                      : MaterialCard(
                          material: s.items[i],
                          onTap: () =>
                              context.push('/material/${s.items[i].id}'),
                        ),
                ),
              ),
            SliverToBoxAdapter(
              child: s.loadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : (!s.loading && !s.hasMore && s.items.isNotEmpty)
                  ? ListEndNote(
                      text: widget.endText(s.total),
                      onScrollTop: widget.showScrollTop
                          ? () => _scroll.animateTo(
                              0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            )
                          : null,
                    )
                  : const SizedBox(height: 20),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 36, color: MColors.hint),
          const SizedBox(height: 8),
          const Text(
            'Материалдарды жүктеу мүмкін болмады',
            style: TextStyle(color: MColors.muted),
          ),
          TextButton(onPressed: onRetry, child: const Text('Қайталау')),
        ],
      ),
    );
  }
}
