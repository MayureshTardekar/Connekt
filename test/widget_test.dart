import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connekt/main.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('runner is alive', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('ok')));
    expect(find.text('ok'), findsOneWidget);
  });

  testWidgets('Connekt App Smoke Test', (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    // Public Supabase *local* demo key (from Supabase docs) + non-production URL
    // for test isolation only (not your app credentials).
    const testUrl = 'https://test-placeholder.supabase.co';
    const testAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

    await Supabase.initialize(
      url: testUrl,
      anonKey: testAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
      ),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: CampusHiveApp(),
      ),
    );
    // Advance time so splash/animation timers are not left pending
    // (would otherwise fail with "A Timer is still pending").
    await tester.pump();
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(MaterialApp), findsOneWidget);

    await Supabase.instance.dispose();
  });
}
