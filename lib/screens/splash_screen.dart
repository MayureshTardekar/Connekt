import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../core/repositories/campus_repository.dart';
import '../core/routing/app_routes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/campus_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _progressController;
  Object? _initializationError;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Staggered animation sequence
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _progressController.forward();
    });

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _initializationError = null);
    
    debugPrint('Splash: Starting bootstrap...');
    
    // Add a global timeout for the entire bootstrap process
    try {
      await _runBootstrapLogic().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Splash: Bootstrap Timeout or Error -> $e');
      if (mounted) {
        // Fallback to login if it hangs too long
        context.go(AppRoutes.login);
      }
    }
  }

  Future<void> _runBootstrapLogic() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    final currentUri = Uri.base;
    final hasAuthCode = currentUri.queryParameters.containsKey('code');

    debugPrint('Splash: Session detected: ${session != null}, Has Auth Code: $hasAuthCode');

    if (session == null) {
      if (hasAuthCode) {
        debugPrint('Splash: Auth code detected. Waiting for auto-login...');
        // Supabase-flutter handles the code exchange automatically.
        // We wait a bit for it to trigger authStateChanges.
        await Future<void>.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        
        // Final check after wait
        if (Supabase.instance.client.auth.currentSession == null) {
           context.go(AppRoutes.login);
           return;
        }
      } else {
        context.go(AppRoutes.login);
        return;
      }
    }

    // If we have a session, proceed to campus check
    final repo = CampusRepository();
    try {
      final isMember = await repo.isMemberOfAnyCampus().timeout(const Duration(seconds: 5));
      if (!mounted) return;

      if (!isMember) {
        context.go(AppRoutes.campusSelect);
        return;
      }

      final campuses = await repo.getMyCampuses().timeout(const Duration(seconds: 5));
      if (!mounted) return;

      if (campuses.isNotEmpty) {
        final firstCampusId = campuses.first['campus_id']?.toString();
        ref.read(selectedCampusIdProvider.notifier).selectCampus(firstCampusId);
      }

      context.go(AppRoutes.dashboard);
    } catch (e) {
      debugPrint('Splash: Campus fetch error -> $e');
       if (mounted) context.go(AppRoutes.dashboard); // Try to enter anyway
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.anonPurple.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo icon with glow
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.hub_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App name
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Connekt',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 44,
                                  letterSpacing: -2,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your campus. Your community.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Container(
                            width: 140,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _progressController.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF818CF8),
                                        Color(0xFFA78BFA),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_initializationError == null)
                            Text(
                              'Checking your campus access...',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                            )
                          else
                            Column(
                              children: [
                                Text(
                                  'Could not finish startup.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please retry your connection.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: _bootstrap,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'CAMPUS COMPANION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
