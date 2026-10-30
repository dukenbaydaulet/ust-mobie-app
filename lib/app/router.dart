import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/materials/detail/document_reader_screen.dart';
import '../features/materials/detail/material_detail_screen.dart';
import '../features/materials/materials_screen.dart';
import '../features/materials/search_screen.dart';
import '../features/my_materials/my_materials_screen.dart';
import '../features/profile/delete_account_screen.dart';
import '../features/profile/help_screen.dart';
import '../features/profile/personal_data_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/subscription_screen.dart';
import '../features/splash/splash_screen.dart';
import 'main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Кіру күйі немесе қонақ режимі өзгерген сайын redirect қайта тексеріледі
  final refresh = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.listen(guestModeProvider, (_, _) => refresh.value++);
  ref.listen(splashDoneProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final guest = ref.read(guestModeProvider);
      final loc = state.matchedLocation;
      final splashDone = ref.read(splashDoneProvider);
      if (!splashDone || (auth.isLoading && !auth.hasValue)) {
        return loc == '/splash' ? null : '/splash';
      }
      final allowed = auth.value != null || guest;
      if (!allowed) return loc == '/login' ? null : '/login';
      // Кіргеннен кейін бірінші ашылатын бет — Материалдар
      if (loc == '/login' || loc == '/splash' || loc == '/') {
        return '/materials';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      // Материал беті (төменгі мәзірсіз) және оны толық экранда оқу
      GoRoute(
        path: '/material/:id',
        builder: (_, state) =>
            MaterialDetailScreen(id: int.parse(state.pathParameters['id']!)),
        routes: [
          GoRoute(
            path: 'read',
            builder: (_, state) => DocumentReaderScreen(
              id: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      // Кабинеттің ішкі беттері (төменгі мәзірсіз)
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const PersonalDataScreen(),
      ),
      GoRoute(
        path: '/profile/delete',
        builder: (_, _) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/account-deleted',
        builder: (_, _) => const AccountDeletedScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (_, _) => const SubscriptionScreen(),
      ),
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/materials',
                builder: (_, _) => const MaterialsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (_, _) => const MyMaterialsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cabinet',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
