import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart' as v2;
import 'core/routing/app_router.dart';
import 'core/config/app_config.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On web, surface build/layout errors instead of a blank page (debug only).
  if (kIsWeb && kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFFF5F5F5),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            'Flutter build error (web debug)\n\n'
            '${details.exceptionAsString()}\n\n'
            '${details.stack}',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      );
    };
  }

    // Initialize Supabase Backend
    if (AppConfig.isSupabaseConfigured) {
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
        );
        debugPrint(
          'Supabase initialized. Session restored: '
          '${Supabase.instance.client.auth.currentSession != null}',
        );
      } catch (e, st) {
        debugPrint('Supabase initialization failed: $e');
        debugPrint('$st');
        rethrow;
      }
    } else {
      debugPrint('---------------------------------------------------------');
      debugPrint('⚠️ CONFIGURE SUPABASE TO UNLOCK LIVE FEATURES');
      debugPrint('MISSING: SUPABASE_URL or SUPABASE_ANON_KEY');
      debugPrint('RUN WITH: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
      debugPrint('CURRENT STATE: Running in Offline/Mock mode.');
      debugPrint('---------------------------------------------------------');
    }

  // Status bar styling is mobile-only; skip on web to avoid edge-case issues.
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  runApp(
    // Wrapping the entire app in ProviderScope so Riverpod can manage state everywhere
    const ProviderScope(child: CampusHiveApp()),
  );
}

class CampusHiveApp extends ConsumerWidget {
  const CampusHiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Connekt',
      debugShowCheckedModeBanner: false,
      theme: v2.AppTheme.lightTheme,
      darkTheme: v2.AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
