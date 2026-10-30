import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/typography.dart';
import '../material.dart';

/// Материалдар бөлімінің түстері.
class MColors {
  // Түстер дизайн суретінен өлшеп алынды
  static const page = Color(0xFFF4F6F9);
  static const text = Color(0xFF0D1C2F);
  static const muted = Color(0xFF64748B);
  static const hint = Color(0xFF94A3B8);

  /// ✕ және ↗ сияқты әлсіз белгішелер
  static const faint = Color(0xFFC3C6D7);
  static const border = Color(0xFFE2E8F0);

  /// Танымал сұрау чиптерінің жиегі
  static const chipBorder = Color(0xFFEDEFF2);
  static const primary = Color(0xFF1E63E9);
  static const primaryDark = Color(0xFF004BC0);
  static const primarySoft = Color(0xFFE6EEFF);
  static const chip = Color(0xFFF1F5F9);

  /// Қызғылт сары: «Танымал сұраулар» белгішесі, бірінші чип, тарих санаты
  static const orange = Color(0xFF8B5000);
  static const orangeSoft = Color(0xFFFFDCBE);
  static const orangeText = Color(0xFF2C1600);
}

/// Жоғарғы тақырып: логотип + USTAZ TILEGI. [onBack] берілсе — артқа батырмасы.
class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    // Күй жолағының (уақыт, батарея) астын да ақ етеміз, белгішелері қара
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        16,
        10 + MediaQuery.paddingOf(context).top,
        16,
        10,
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            InkResponse(
              onTap: onBack,
              radius: 20,
              child: const Icon(
                Icons.arrow_back,
                size: 22,
                color: MColors.text,
              ),
            ),
            const SizedBox(width: 14),
          ],
          SvgPicture.asset('assets/images/logo.svg', height: 20),
          const SizedBox(width: 6),
          SvgPicture.asset(
            'assets/images/wordmark.svg',
            width: 105,
            height: 14,
            colorFilter: const ColorFilter.mode(
              Color(0xFF363636),
              BlendMode.srcIn,
            ),
            semanticsLabel: 'USTAZ TILEGI',
          ),
        ],
      ),
    );
  }
}

/// Ақ іздеу өрісі (басты бетте — басқанда іздеу беті ашылады).
class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    this.controller,
    this.focusNode,
    this.hint = 'Сабақ жоспары, ҚМЖ, ТЖБ, БЖБ...',
    this.readOnly = false,
    this.autofocus = false,
    this.focused = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;
  final bool readOnly;
  final bool autofocus;

  /// Көк жиек (іздеу беті ашық тұрғанда)
  final bool focused;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? MColors.primary : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          if (!focused) ...[
            const SizedBox(width: 14),
            const Icon(Icons.search, size: 20, color: MColors.primary),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: readOnly,
              autofocus: autofocus,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: AppText.input,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppText.placeholder,
              ),
            ),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18, color: MColors.hint),
              splashRadius: 18,
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Сүзгі батырмасы: «Пән ⌄», «Сынып ② ⌄».
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: active
              ? MColors.primary.withValues(alpha: 0.4)
              : MColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppText.filterChip),
              if (active) ...[
                const SizedBox(width: 6),
                CountBadge(count: count),
              ],
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: MColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Кішкентай көк дөңгелек сан.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MColors.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Пән / Бағыт / Сынып сүзгілері және тазалау батырмасы.
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.filters,
    required this.onSubjects,
    required this.onDirections,
    required this.onGrades,
    required this.onClear,
  });

  final MaterialFilters filters;
  final VoidCallback onSubjects;
  final VoidCallback onDirections;
  final VoidCallback onGrades;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChipButton(
            label: 'Пән',
            count: filters.subjects.length,
            onTap: onSubjects,
          ),
          const SizedBox(width: 8),
          FilterChipButton(
            label: 'Бағыт',
            count: filters.directions.length,
            onTap: onDirections,
          ),
          const SizedBox(width: 8),
          FilterChipButton(
            label: 'Сынып',
            count: filters.grades.length,
            onTap: onGrades,
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: MColors.border),
            ),
            child: InkWell(
              onTap: filters.isEmpty ? null : onClear,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: filters.isEmpty ? MColors.hint : MColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «411 982 материал табылды»
class FoundCount extends StatelessWidget {
  const FoundCount({super.key, required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.verified_outlined, size: 18, color: MColors.primary),
        const SizedBox(width: 6),
        Text('${formatNumber(total)} материал табылды', style: AppText.label),
      ],
    );
  }
}

/// 411982 -> "411 982"
String formatNumber(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Материал карточкасы.
class MaterialCard extends StatelessWidget {
  const MaterialCard({super.key, required this.material, this.onTap});
  final StudyMaterial material;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FileTypeIcon(type: material.fileType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      // 2 жолға сыю үшін жол аралығы 100%-дан сәл үлкен
                      style: AppText.cardTitle.copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (material.grade != null)
                          _Tag(
                            material.grade!,
                            color: AppText.link,
                            background: MColors.primarySoft,
                          ),
                        if (material.subject != null)
                          _Tag(
                            material.subject!,
                            color: AppText.slate,
                            background: const Color(0xFFDDE9FF),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      material.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      // Екі жол бір-біріне тиіп қалмауы үшін 1.25
                      style: AppText.description.copyWith(height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color, required this.background});
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: AppText.tag.copyWith(color: color)),
    );
  }
}

/// Файл түрінің белгішесі (DOC — көк, PPT/PDF — қызыл).
class FileTypeIcon extends StatelessWidget {
  const FileTypeIcon({super.key, required this.type, this.size = 44});
  final String type;

  /// Қораптың өлшемі (белгіше одан ~60%)
  final double size;

  /// assets/images/material/ ішінде белгішесі бар түрлер
  static const _known = {
    'doc',
    'docx',
    'dot',
    'rtf',
    'pdf',
    'ppt',
    'pptx',
    'jpg',
    'jpeg',
    'png',
    'svg',
    'zip',
    'rar',
  };

  static Color _background(String t) => switch (t) {
    'ppt' || 'pptx' || 'pdf' => const Color(0xFFFDECEC),
    'zip' || 'rar' => const Color(0xFFFFF4E0),
    'jpg' || 'jpeg' || 'png' || 'svg' => const Color(0xFFE9F7EF),
    _ => MColors.primarySoft,
  };

  @override
  Widget build(BuildContext context) {
    final t = type.toLowerCase();
    final asset = _known.contains(t) ? t : 'doc';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _background(t),
        borderRadius: BorderRadius.circular(size * 0.23),
      ),
      child: SvgPicture.asset(
        'assets/images/material/$asset.svg',
        width: size * 0.6,
        height: size * 0.6,
        semanticsLabel: t.toUpperCase(),
      ),
    );
  }
}

/// Тізімнің соңындағы жазу: «Барлық жаңа материалдар жүктелді».
class ListEndNote extends StatelessWidget {
  const ListEndNote({super.key, required this.text, this.onScrollTop});
  final String text;
  final VoidCallback? onScrollTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.done_all,
            size: 18,
            color: MColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center, style: AppText.caption),
          if (onScrollTop != null) ...[
            const SizedBox(height: 10),
            Material(
              color: MColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onScrollTop,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 14,
                        color: MColors.primaryDark,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Жоғарыға оралу',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Бөлім тақырыбы: белгіше + мәтін + (оң жақта әрекет).
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor = MColors.text,
    this.iconBackground,
    this.action,
    this.onAction,
    this.small = false,
  });

  final IconData icon;
  final String title;

  /// Кіші тақырып (карточка ішінде): Arimo 600 14/18
  final bool small;
  final Color iconColor;
  final Color? iconBackground;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        iconBackground == null
            ? Icon(icon, size: 18, color: iconColor)
            : Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: small ? AppText.label : AppText.sectionTitle,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: AppText.smallLink),
          ),
      ],
    );
  }
}

/// Танымал сұраулар (чиптер). Біріншісі қызғылт сары.
class PopularQueries extends StatelessWidget {
  const PopularQueries({super.key, required this.queries, required this.onTap});
  final List<String> queries;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < queries.length; i++)
          Material(
            color: i == 0 ? MColors.orangeSoft : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: i == 0
                  ? BorderSide.none
                  : const BorderSide(color: MColors.chipBorder),
            ),
            child: InkWell(
              onTap: () => onTap(queries[i]),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Белгіше емес, от смайлигі
                    if (i == 0) ...[
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      queries[i],
                      style: i == 0 ? AppText.chipStrong : AppText.chip,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Тізім жүктеліп жатқандағы бос карточкалар.
class MaterialCardSkeleton extends StatelessWidget {
  const MaterialCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: MColors.chip,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(44, 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(double.infinity, 14),
                const SizedBox(height: 6),
                bar(160, 14),
                const SizedBox(height: 10),
                bar(120, 12),
                const SizedBox(height: 10),
                bar(double.infinity, 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
