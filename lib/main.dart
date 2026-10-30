import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/colors.dart';
import 'app/router.dart';

void main() {
  // retry: null — желі қатесінде provider-лерді автоматты қайталамаймыз
  runApp(ProviderScope(retry: (_, _) => null, child: const UstApp()));
}

class UstApp extends ConsumerWidget {
  const UstApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Ustaz Tilegi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
