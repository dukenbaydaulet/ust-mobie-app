import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/typography.dart';
import '../../materials/widgets/material_widgets.dart';
import '../auth_controller.dart';

/// Қонақ режимінде жабық бөлімдер үшін: «Кіру / Тіркелу» ұсынысы.
/// «Материалдарым», «Кабинет» сияқты беттерде қолданылады.
class GuestLoginPrompt extends ConsumerWidget {
  const GuestLoginPrompt({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Қонақ режимінен шыққанда router өзі кіру бетіне апарады
    void login() => ref.read(guestModeProvider.notifier).exit();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: MColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppText.link),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: AppText.emptyTitle),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.hintText.copyWith(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: login,
                iconAlignment: IconAlignment.end,
                style: FilledButton.styleFrom(
                  backgroundColor: MColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.login, size: 18),
                label: Text(
                  'Кіру',
                  style: AppText.action.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton.icon(
                onPressed: login,
                style: TextButton.styleFrom(
                  backgroundColor: MColors.primarySoft,
                  foregroundColor: AppText.link,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: Text(
                  'Тіркелу',
                  style: AppText.action.copyWith(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/images/logo.svg', height: 12),
                const SizedBox(width: 6),
                Text(
                  'Қазақстан ұстаздарының ресми қауымдастығы',
                  style: AppText.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
