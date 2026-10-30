import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../features/materials/widgets/material_widgets.dart';
import '../features/my_materials/my_materials_screen.dart';

/// Төменгі мәзір: Материалдар / Материалдарым / Кабинет.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  /// (SVG белгіше немесе Material белгіше, атауы)
  static const _items = [
    ('assets/images/material/icon_material.svg', null, 'Материалдар'),
    (
      'assets/images/material/icon_meini_materialdarym.svg',
      null,
      'Материалдарым',
    ),
    (null, Icons.account_circle_outlined, 'Кабинет'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(int i) {
      // «Материалдарым» басқа бөлімнен ашылса — әрқашан «Жүктелгендер»
      if (i == 1 && shell.currentIndex != 1) {
        ref.read(myMaterialsVisitProvider.notifier).next();
      }
      shell.goBranch(i, initialLocation: i == shell.currentIndex);
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: MColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: InkResponse(
                      onTap: () => open(i),
                      highlightShape: BoxShape.rectangle,
                      child: _NavItem(
                        svg: _items[i].$1,
                        icon: _items[i].$2,
                        label: _items[i].$3,
                        active: i == shell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.svg,
    required this.icon,
    required this.label,
    required this.active,
  });
  final String? svg;
  final IconData? icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? MColors.primary : MColors.muted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        svg != null
            ? SvgPicture.asset(
                svg!,
                width: 22,
                height: 22,
                // Белгіше түсі белсенді күйге қарай өзгереді
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              )
            : Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
