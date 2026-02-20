// ExecPrompt - AI LLM Mobile Client
// Copyright (C) 2026 DayOfGeek.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'domain/providers/endpoint_provider.dart';
import 'domain/providers/settings_provider.dart';
import 'presentation/theme/cyberterm_theme.dart';
import 'presentation/screens/adaptive_shell.dart';
import 'presentation/screens/models_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ExecPromptApp(),
    ),
  );
}

class ExecPromptApp extends ConsumerWidget {
  const ExecPromptApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    // Initialize endpoints (loads from storage + migrates legacy settings).
    // This is a fire-and-forget — the app works even if it's still loading.
    ref.watch(endpointsInitProvider);

    // Load search API keys from secure storage (migrates from prefs if needed).
    ref.watch(searchKeysInitProvider);

    return MaterialApp.router(
      title: 'ExecPrompt',
      debugShowCheckedModeBanner: false,
      theme: buildCyberTermTheme(currentTheme),
      darkTheme: buildCyberTermTheme(currentTheme),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}

/// Custom slide transition page for smooth navigation
CustomTransitionPage<void> _buildPageWithSlideTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    },
  );
}

final _router = GoRouter(
  initialLocation: '/chat',
  routes: [
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const AdaptiveShell(),
    ),
    GoRoute(
      path: '/models',
      name: 'models',
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        child: const ModelsScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        child: const SettingsScreen(),
        state: state,
      ),
    ),
  ],
);
