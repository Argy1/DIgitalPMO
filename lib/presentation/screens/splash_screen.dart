import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/sync/sync_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    unawaited(_continueStartup());
  }

  Future<void> _continueStartup() async {
    _animationController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      await _checkAuthState();
    }
  }

  Future<void> _checkAuthState() async {
    final seenOnboarding =
        Hive.box<dynamic>(HiveBoxes.settings).get('hasSeenOnboarding', defaultValue: false) == true;
    var destination = seenOnboarding ? '/login' : '/onboarding';

    try {
      final hasToken = await ApiService.instance.hasValidToken().timeout(
        const Duration(seconds: 3),
      );
      if (!hasToken) {
        // No token at all → go to login/onboarding (destination already set).
        if (mounted) context.go(destination);
        return;
      }

      // Token exists — validate it by fetching profile.
      try {
        final profileData = await ApiService.instance.getMyProfile().timeout(
          const Duration(seconds: 6),
        );
        final user = profileData['user'] as Map<String, dynamic>?;
        if ((user?['role'] as String?) == 'pmo') {
          destination = '/pmo/dashboard';
        } else {
          destination = '/home/dashboard';
        }
      } on ServerException catch (e) {
        // 401 = token expired / invalid → clear and go to login.
        if (e.statusCode == 401) {
          await ApiService.instance.logout();
        }
        // Any server error: fall through to login (destination already set).
      } catch (_) {
        // Network error etc. — token might still be valid; go to dashboard
        // so user can retry from there rather than being forced to re-login.
        destination = '/home/dashboard';
      }
    } catch (error, stack) {
      debugPrint('Splash routing fallback: $error\n$stack');
    }

    if (mounted) {
      context.go(destination);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDeep],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.favorite, size: 60, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'DigitalPMO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
