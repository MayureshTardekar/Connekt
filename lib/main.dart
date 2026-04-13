import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Backend
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Make status bar transparent for a modern look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    // Wrapping the entire app in ProviderScope so Riverpod can manage state everywhere
    const ProviderScope(child: CampusHiveApp()),
  );
}

class CampusHiveApp extends StatelessWidget {
  const CampusHiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Connekt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
