import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/session/session_page.dart';
import 'data/providers/local_db_provider.dart';
import 'features/settings/providers/theme_provider.dart';
import 'data/providers/dashboard_providers.dart';

// Local database provider
final localDbProvider = Provider<LocalDbProvider>((ref) {
  return LocalDbProvider();
});

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeStorage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 앱 종료 시 백엔드 정리
    _stopBackend();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 완전히 종료될 때 백엔드 정리
    if (state == AppLifecycleState.detached) {
      _stopBackend();
    }
  }

  Future<void> _stopBackend() async {
    try {
      final backendManager = ref.read(backendManagerProvider);
      await backendManager.stopBackend();
      print('✓ Backend stopped successfully');
    } catch (e) {
      print('Error stopping backend: $e');
    }
  }

  Future<void> _initializeStorage() async {
    // Initialize SharedPreferences storage provider
    final storage = ref.read(storageProvider);
    await storage.init();

    // Initialize SQLite database provider
    final localDb = ref.read(localDbProvider);
    await localDb.database;

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render until storage is initialized
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Watch theme mode from theme provider
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'NewWork',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          // Check if onboarding is completed
          // This will be handled by the OnboardingPage itself
          return null;
        },
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/session/:id',
        builder: (context, state) {
          final sessionId = state.pathParameters['id']!;
          return SessionPage(sessionId: sessionId);
        },
      ),
    ],
  );
}
