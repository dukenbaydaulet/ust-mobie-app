import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../material.dart';
import '../materials_repository.dart';
import 'material_widgets.dart';

enum FilterKind { subjects, directions, grades }

/// Сүзгі терезесін ашады. «Көрсету» басылса — жаңа сүзгілерді қайтарады.
Future<MaterialFilters?> showFilterSheet(
  BuildContext context, {
  required FilterKind kind,
  required MaterialFilters initial,
  String query = '',
}) {
  return showModalBottomSheet<MaterialFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Төменгі мәзірдің де үстінен ашылады
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(kind: kind, initial: initial, query: query),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({
    required this.kind,
    required this.initial,
    required this.query,
  });
  final FilterKind kind;
  final MaterialFilters initial;
  final String query;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late Set<String> _selected = {..._field(widget.initial)};
  late Future<int> _count = _loadCount();

  /// Нұсқалар және олардың саны (басқа таңдалған сүзгілерді ескереді)
  late final Future<List<FilterOption>> _options = _loadOptions();
  String _subjectSearch = '';

  Future<List<FilterOption>> _loadOptions() {
    final repo = ref.read(materialsRepositoryProvider);
    final q = widget.query;
    final f = widget.initial;
    return switch (widget.kind) {
      FilterKind.subjects => repo.subjects(query: q, filters: f),
      FilterKind.directions => repo.directions(query: q, filters: f),
      FilterKind.grades => repo.grades(query: q, filters: f),
    };
  }

  Set<String> _field(MaterialFilters f) => switch (widget.kind) {
    FilterKind.subjects => f.subjects,
    FilterKind.directions => f.directions,
    FilterKind.grades => f.grades,
  };

  MaterialFilters get _draft => switch (widget.kind) {
    FilterKind.subjects => widget.initial.copyWith(subjects: _selected),
    FilterKind.directions => widget.initial.copyWith(directions: _selected),
    FilterKind.grades => widget.initial.copyWith(grades: _selected),
  };

  Future<int> _loadCount() => ref
      .read(materialsRepositoryProvider)
      .count(query: widget.query, filters: _draft);

  void _toggle(String id) {
    setState(() {
      _selected = {..._selected};
      _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
      _count = _loadCount();
    });
  }

  void _clearAll() {
    setState(() {
      _selected = {};
      _count = _loadCount();
    });
  }

  String get _title => switch (widget.kind) {
    FilterKind.subjects => 'Пән',
    FilterKind.directions => 'Бағыт',
    FilterKind.grades => 'Сынып',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: MColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: MColors.text,
                    ),
                  ),
                  if (_selected.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: MColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_selected.length} таңдалды',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Material(
                    color: MColors.primarySoft,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF424654),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<List<FilterOption>>(
                future: _options,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Жүктеу мүмкін болмады',
                        style: TextStyle(color: MColors.muted),
                      ),
                    );
                  }
                  final list = snap.data;
                  if (list == null) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return switch (widget.kind) {
                    FilterKind.grades => _gradesBody(list),
                    FilterKind.subjects => _listBody(list, withSearch: true),
                    FilterKind.directions => _listBody(
                      list,
                      allLabel: 'Барлық бағыттар',
                    ),
                  };
                },
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  /// «Барлық ...» нұсқасы: басқанда таңдау тазаланады.
  Widget _allOption(String label) {
    final active = _selected.isEmpty;
    return Material(
      color: active ? const Color(0xFFEFF4FF) : MColors.page,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _clearAll,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: MColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$label бойынша іздеу',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              // Дизайндағыдай: сұр қос белгі
              const Icon(Icons.done_all, size: 20, color: Color(0xFF737686)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listBody(
    List<FilterOption> list, {
    bool withSearch = false,
    String? allLabel,
  }) {
    final q = _subjectSearch.trim().toLowerCase();
    final shown = q.isEmpty
        ? list
        : list.where((o) => o.name.toLowerCase().contains(q)).toList();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      children: [
        if (allLabel != null) ...[
          _allOption(allLabel),
          const SizedBox(height: 8),
        ],
        if (withSearch) ...[
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: MColors.page,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: MColors.hint),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _subjectSearch = v),
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Пәнді іздеу...',
                      hintStyle: TextStyle(fontSize: 14, color: MColors.hint),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        for (final o in shown) _checkRow(o),
        if (shown.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Ештеңе табылмады',
                style: TextStyle(color: MColors.muted),
              ),
            ),
          ),
      ],
    );
  }

  Widget _checkRow(FilterOption o) {
    final on = _selected.contains(o.id);
    return Material(
      color: on
          ? MColors.primarySoft.withValues(alpha: 0.6)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _toggle(o.id),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              _CheckBox(on: on),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  o.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                    color: on ? MColors.primaryDark : MColors.text,
                  ),
                ),
              ),
              if (o.count == null)
                const SizedBox.shrink()
              else if (on)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    formatNumber(o.count!),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MColors.primaryDark,
                    ),
                  ),
                )
              else
                Text(
                  formatNumber(o.count!),
                  style: const TextStyle(fontSize: 12, color: MColors.muted),
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradesBody(List<FilterOption> list) {
    // «Мектепке дейінгі» — тордың үстінде, «Басқа» — астында, толық енмен
    final preschool = list
        .where((o) => o.type == FilterOptionType.preschool)
        .toList();
    final others = list.where((o) => o.type == FilterOptionType.other).toList();
    final numbered = list
        .where((o) => o.type == FilterOptionType.regular)
        .toList();
    Widget wideTile(FilterOption o, IconData icon) {
      final on = _selected.contains(o.id);
      return Material(
        color: on
            ? MColors.primaryDark
            : MColors.primarySoft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _toggle(o.id),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: on ? Colors.white : const Color(0xFF424654),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    o.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                      color: on ? Colors.white : MColors.text,
                    ),
                  ),
                ),
                if (on) const Icon(Icons.check, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      children: [
        _allOption('Барлық сыныптар'),
        const SizedBox(height: 12),
        const Divider(height: 1, color: MColors.border),
        const SizedBox(height: 12),
        for (final o in preschool) ...[
          wideTile(o, Icons.sentiment_satisfied_alt_outlined),
          const SizedBox(height: 10),
        ],
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          // Әйтпесе экранның төменгі safe area-сы қосылып, «Басқа» алыстап кетеді
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.3,
          children: [
            for (final o in numbered)
              Material(
                color: _selected.contains(o.id)
                    ? MColors.primaryDark
                    : MColors.primarySoft.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _toggle(o.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          o.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selected.contains(o.id)
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selected.contains(o.id)
                                ? Colors.white
                                : MColors.text,
                          ),
                        ),
                        if (_selected.contains(o.id))
                          const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (final o in others) ...[
          const SizedBox(height: 10),
          wideTile(o, Icons.category_outlined),
        ],
      ],
    );
  }

  Widget _footer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MColors.border)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _selected.isEmpty ? null : _clearAll,
            style: TextButton.styleFrom(foregroundColor: MColors.muted),
            child: const Text('Тазалау', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: MColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(_draft),
                child: FutureBuilder<int>(
                  future: _count,
                  builder: (context, snap) => Text(
                    snap.hasData
                        ? 'Көрсету  (${formatNumber(snap.data!)})'
                        : 'Көрсету',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: on ? MColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: on ? MColors.primary : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: on ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }
}
