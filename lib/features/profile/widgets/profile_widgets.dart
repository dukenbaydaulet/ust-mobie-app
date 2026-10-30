import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/typography.dart';
import '../../materials/widgets/material_widgets.dart';

// Кабинет беттерінің түстері — дизайн суретінен өлшеп алынды
class PColors {
  static const red = Color(0xFFDC2626);
  static const redDeep = Color(0xFFBA1A1A);
  static const redSoft = Color(0xFFFFE4E6);
  static const pink = Color(0xFFE11D48);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFDCFCE7);
  static const iconBg = Color(0xFFEEF2FF);
  static const soft = Color(0xFFF1F4FA);
  static const field = Color(0xFFF8FAFC);
  static const disabled = Color(0xFFEFF2F6);
  static const shadow = [
    BoxShadow(color: Color(0x0F0D1C2F), blurRadius: 12, offset: Offset(0, 2)),
  ];
}

// Мәтін стильдері
class PText {
  /// Беттің үлкен тақырыбы: «Аккаунтыңызды жоясыз ба?» — Arimo 600 22/28
  static const title = AppText.emptyTitle;

  /// Карточка тақырыбы: «Жеке мәліметтер» — Arimo 600 18/24
  static const cardTitle = AppText.sectionTitle;

  /// Жол атауы: «Жазылымды басқару» — Inter 500 14/20
  static const row = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
    color: AppText.ink,
  );

  /// Жолдың қалың атауы: «Құпия сөзді өзгерту» — Inter 600 14/20
  static const rowStrong = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    color: AppText.ink,
  );

  /// Түсіндірме: Inter 400 13/18, сұр
  static const lead = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 18 / 13,
    color: AppText.muted,
  );

  /// Өріс атауы: «Тегіңіз (Фамилия)» — Inter 500 12/16
  static const fieldLabel = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
    color: AppText.slate,
  );

  /// Кіші мәтін: Inter 400 11/14
  static const small = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 11,
    height: 14 / 11,
    color: AppText.muted,
  );
}

/// Ақ жоғарғы жолақ: ← және ортасында атауы.
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({super.key, required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.only(top: top),
        height: 56 + top,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack ?? () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: AppText.ink),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.topBarTitle.copyWith(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// Ақ карточка, бұрышы 16, жеңіл көлеңке.
class WhiteCard extends StatelessWidget {
  const WhiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: color == Colors.white ? PColors.shadow : null,
      ),
      child: child,
    );
  }
}

/// Жұмсақ фондағы белгіше: 36×36, бұрышы 10.
class IconBox extends StatelessWidget {
  const IconBox({
    super.key,
    required this.icon,
    this.color = MColors.primary,
    this.background = PColors.iconBg,
    this.size = 36,
    this.circle = false,
  });
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(10),
      ),
      child: Icon(icon, size: size * 0.55, color: color),
    );
  }
}

/// Батырма: толық ені, биіктігі 50, бұрышы 12, түсті көлеңкемен.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailing,
    this.color = MColors.primary,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailing;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.action.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailing, size: 18, color: Colors.white),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Қате / хабар көрсету
/// Сілтемені телефонның браузерінде ашады.
Future<void> openLink(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
