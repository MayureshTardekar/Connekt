import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connekt/main.dart';
import 'package:connekt/core/config/app_config.dart';

void main() {
  testWidgets('Connekt App Smoke Test', (WidgetTester tester) async {
    // Initialize Supabase with placeholders for the test environment
    // to prevent assertion errors when the app accesses Supabase.instance.
    await Supabase.initialize(
      url: AppConfig.supabaseUrl, 
      anonKey: AppConfig.supabaseAnonKey,
    );

    // Build our app under ProviderScope for Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: CampusHiveApp(),
      ),
    );

    // Initial check for app structure
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
