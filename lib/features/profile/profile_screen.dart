import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/typography.dart';
import '../../core/config.dart';
import '../auth/auth_controller.dart';
import '../auth/user.dart';
import '../auth/widgets/guest_login_prompt.dart';
import '../materials/widgets/material_widgets.dart';
import 'profile_repository.dart';
import 'widgets/profile_widgets.dart';

/// «Кабинет» — профиль, жазылым, баптаулар.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    // Қонаққа — «Материалдарым» бетіндегідей кіру ұсынысы
    if (user == null) {
      return const Scaffold(
        backgroundColor: MColors.page,
        body: Column(
          children: [
            LogoHeader(),
            Expanded(
              child: GuestLoginPrompt(
                icon: Icons.account_circle_outlined,
                title: 'Жеке кабинет',
                text: 'Баланс, жазылым және сатып алулар туралы мәліметті көру үшін кабинетке кіріңіз.',
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: MColors.page,
      body: Column(
        children: [
          const LogoHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(subscriptionProvider);
                await ref.read(authProvider.notifier).reload();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _UserCard(user: user),
                  const SizedBox(height: 16),
                  const _SubscriptionCard(),
                  const SizedBox(height: 16),
                  const _Menu(),
                  const SizedBox(height: 16),
                  const _LogoutButton(),
                  const SizedBox(height: 20),
                  Text(
                    'Ustaz tilegi v${AppConfig.version} • ust.kz порталының серіктес қосымшасы',
                    textAlign: TextAlign.center,
                    style: PText.small,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Барлық құқықтар қорғалған © ${DateTime.now().year}',
                    textAlign: TextAlign.center,
                    style: PText.small.copyWith(fontSize: 10),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => openLink(AppConfig.privacyPolicyUrl),
                      child: Text(
                        'Құпиялылық саясаты',
                        style: PText.small.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: AppText.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Дөңгелек аватар: сурет болмаса — жұмсақ қызғылт сары фондағы белгіше.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.url, this.size = 56});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = SvgPicture.asset(
      'assets/images/profile-circle.svg',
      width: size,
      height: size,
    );
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(url: user.avatar, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? 'Пайдаланушы' : user.name,
                  style: _K.name,
                ),
                const SizedBox(height: 2),
                Text(user.phone, style: _K.phone),
                const SizedBox(height: 6),
                Text('ID: ${user.displayId}', style: _K.id),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Material(
              color: _K.chipBg,
              shape: const StadiumBorder(),
              child: InkWell(
                onTap: () => context.push('/profile/edit'),
                customBorder: const StadiumBorder(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Өңдеу', style: _K.edit),
                      SizedBox(width: 4),
                      Icon(Symbols.edit, size: 12, color: _K.blue),
                    ],
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

/// Ақ карточка: бұрышы 12, жеңіл көлеңке.
const _card = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(12)),
  boxShadow: [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ],
);

/// Жазылым карточкасы мен «Толық ашу» батырмасының көлеңкесі.
const _raised = [
  BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 4,
    spreadRadius: -2,
    offset: Offset(0, 2),
  ),
  BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 6,
    spreadRadius: -1,
    offset: Offset(0, 4),
  ),
];

// Кабинеттің дизайн мәндері
class _K {
  static const blue = Color(0xFF004BC0);
  static const chipBg = Color(0xFFEFF4FF);
  static const pale = Color(0xFFD5E3FD);
  static const orange = Color(0xFFFF9800);
  static const orangeText = Color(0xFF653900);

  static const name = TextStyle(
    fontFamily: 'Arimo',
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    color: AppText.ink,
  );
  static const phone = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 16 / 12,
    color: AppText.muted,
  );
  static const id = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    height: 12 / 10,
    color: AppText.muted,
  );
  static const edit = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 10,
    height: 12 / 10,
    color: blue,
  );
  static const chip = TextStyle(
    fontFamily: 'Arimo',
    fontSize: 10,
    height: 12 / 10,
    letterSpacing: 0.5,
    color: Colors.white,
  );
  static const subTitle = TextStyle(
    fontFamily: 'Arimo',
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1,
    color: Colors.white,
  );
  static const subLead = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 16.5 / 12,
    color: pale,
  );
  static const button = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 18 / 14,
    color: orangeText,
  );
  static const terms = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    height: 12 / 10,
    color: pale,
  );
  static const row = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 20 / 14,
    color: AppText.ink,
  );
  static const logout = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 18 / 14,
    color: PColors.redDeep,
  );
}

/// Көк градиентті жазылым карточкасы.
class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider).value;
    void open() => context.push('/subscription');

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_K.blue, Color(0xFF1E63E9), Color(0xFF233144)],
        ),
        boxShadow: _raised,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: const ShapeDecoration(
                  color: Color(0xFF254889),
                  shape: StadiumBorder(),
                  shadows: [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('assets/images/jazlym.svg', height: 14),
                    const SizedBox(width: 6),
                    const Text('ЖАЗЫЛЫМ', style: _K.chip),
                  ],
                ),
              ),
              const Spacer(),
              SvgPicture.asset('assets/images/U.svg', height: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sub == null ? 'Сізде жазылым жоқ' : sub.title,
            style: _K.subTitle,
          ),
          const SizedBox(height: 4),
          Text(
            sub == null
                ? 'Барлық мүмкіндіктерге толық қол жеткізіңіз'
                : '${formatDate(sub.to)} дейін жарамды · '
                      'қалғаны ${sub.daysLeft} күн',
            style: _K.subLead,
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              boxShadow: _raised,
            ),
            child: Material(
              color: _K.orange,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: open,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (sub == null)
                        SvgPicture.asset(
                          'assets/images/naizagai.svg',
                          height: 15,
                        )
                      else
                        const Icon(
                          Symbols.tune,
                          size: 16,
                          color: _K.orangeText,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        sub == null ? 'Толық ашу' : 'Жазылымды басқару',
                        style: _K.button,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: open,
            behavior: HitTestBehavior.opaque,
            child: const Text(
              'Тариф шарттарымен танысыңыз',
              textAlign: TextAlign.center,
              style: _K.terms,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _Menu extends ConsumerWidget {
  const _Menu();

  /// «Офлайн сақтау баптаулары» жолы әзірге жасырын.
  static const _showOfflineSettings = false;

  /// «Хабарландырулар» жасырын: push (Firebase) әлі қосылмаған, ал жұмыс
  /// істемейтін баптау дүкен тексеруінен өтпейді.
  static const _showNotifications = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const divider = Divider(height: 1, color: Color(0xFFF1F4FA));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: _card,
      child: Column(
        children: [
          _MenuRow(
            svg: 'card',
            title: 'Жазылымды басқару',
            onTap: () => context.push('/subscription'),
          ),
          if (_showOfflineSettings) ...[
            divider,
            _MenuRow(
              svg: 'off_baptau',
              title: 'Офлайн сақтау баптаулары',
              subtitle: switch (ref.watch(freeSpaceProvider).value) {
                null => null,
                final free => '${_megabytes(free)} бос орын бар',
              },
              trailing: _Switch(
                value: ref.watch(offlineSaveProvider),
                onChanged: ref.read(offlineSaveProvider.notifier).set,
              ),
            ),
          ],
          if (_showNotifications) ...[
            divider,
            _MenuRow(
              svg: 'habar',
              title: 'Хабарландырулар',
              trailing: _Switch(
                value: ref.watch(notificationsProvider),
                onChanged: ref.read(notificationsProvider.notifier).set,
              ),
            ),
          ],
          divider,
          _MenuRow(
            svg: 'komek',
            svgColor: const Color(0xFF004BC0),
            title: 'Қолдау қызметі (WhatsApp / Call)',
            onTap: () => context.push('/help'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: MColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppText.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// «128 MB» / «12,4 GB»
  static String _megabytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb < 1024) return '${mb.round()} MB';
    return '${(mb / 1024).toStringAsFixed(1).replaceAll('.', ',')} GB';
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.svg,
    this.svgColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  /// assets/images ішіндегі svg аты (кеңейтусіз).
  final String svg;

  /// svg-дің өз түсін ауыстыру үшін.
  final Color? svgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _K.chipBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                'assets/images/$svg.svg',
                width: 18,
                height: 18,
                colorFilter: svgColor == null
                    ? null
                    : ColorFilter.mode(svgColor!, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _K.row),
                  if (subtitle != null) Text(subtitle!, style: PText.small),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: AppText.muted),
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: MColors.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: MColors.border,
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        // Белгіше берілсе, өшірулі күйде де дөңгелек кішіреймейді
        thumbIcon: const WidgetStatePropertyAll(
          Icon(Icons.circle, color: Colors.transparent),
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: _card,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => ref.read(authProvider.notifier).logout(),
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.logout, size: 18, color: PColors.redDeep),
                SizedBox(width: 8),
                Text('Аккаунттан шығу', style: _K.logout),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
