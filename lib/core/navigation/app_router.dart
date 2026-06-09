import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/index.dart';
import '../widgets/pmo_bottom_nav.dart';

const _homeNavRoutes = [
  '/home/dashboard',
  '/home/statistics',
  '/home/ai-chat',
  '/home/symptoms',
  '/home/settings',
];

const _homeNavItems = [
  PMONavItem(icon: Icons.home_rounded, label: 'Beranda'),
  PMONavItem(icon: Icons.bar_chart_rounded, label: 'Statistik'),
  PMONavItem(icon: Icons.auto_awesome_rounded, label: 'PMO AI'),
  PMONavItem(icon: Icons.favorite_rounded, label: 'Gejala'),
  PMONavItem(icon: Icons.settings_rounded, label: 'Setelan'),
];

int _homeTabIndex(String location) {
  final index = _homeNavRoutes.indexWhere(
    (route) => location.startsWith(route),
  );
  return index < 0 ? 0 : index;
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // TODO: Implement redirect logic based on auth state
    // - Tidak ada token → /login
    // - Ada token tapi belum setup profil → /setup-profile
    // - Belum lihat onboarding → /onboarding
    // - Sudah login + profil lengkap → /home/dashboard
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const OnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const RegisterScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/otp/:phoneNumber/:fullName',
      name: 'otp',
      pageBuilder: (context, state) {
        final phoneNumber = state.pathParameters['phoneNumber'] ?? '';
        final fullName = state.pathParameters['fullName'] ?? '';
        final devOtp = state.uri.queryParameters['devOtp'];
        return CustomTransitionPage(
          child: OTPScreen(
            phoneNumber: phoneNumber,
            fullName: fullName,
            devOtp: devOtp,
          ),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/setup-profile/:phoneNumber/:fullName',
      name: 'setupProfile',
      pageBuilder: (context, state) {
        final phoneNumber = state.pathParameters['phoneNumber'] ?? '';
        final fullName = state.pathParameters['fullName'] ?? '';
        return CustomTransitionPage(
          child: ProfileSetupScreen(
            phoneNumber: phoneNumber,
            fullName: fullName,
          ),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
              child: child,
            );
          },
        );
      },
    ),
    // ── PMO routes (akun Pengawas Minum Obat) ────────────────────────────────
    GoRoute(
      path: '/pmo/dashboard',
      name: 'pmoDashboard',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const PMODashboardScreen(),
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/pmo/link',
      name: 'pmoLink',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const PMOLinkScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/pmo/patient/:id',
      name: 'pmoPatientDetail',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          child: PMOPatientDetailScreen(patientId: id),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
              child: child,
            );
          },
        );
      },
    ),
    ShellRoute(
      builder: (context, state, child) => Scaffold(
        body: child,
        bottomNavigationBar: PMOBottomNav(
          currentIndex: _homeTabIndex(state.uri.path),
          items: _homeNavItems,
          onTap: (index) => context.go(_homeNavRoutes[index]),
        ),
      ),
      routes: [
        GoRoute(
          path: '/home/dashboard',
          name: 'dashboard',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const DashboardScreen(),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
          ),
        ),
        GoRoute(
          path: '/home/statistics',
          name: 'statistics',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const StatisticsScreen(),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
          ),
        ),
        GoRoute(
          path: '/home/ai-chat',
          name: 'aiChat',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const AIChatScreen(),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
          ),
        ),
        GoRoute(
          path: '/home/symptoms',
          name: 'symptoms',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const SymptomInputScreen(),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
          ),
        ),
        GoRoute(
          path: '/home/settings',
          name: 'settings',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const SettingsScreen(),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/settings/edit-profile',
      name: 'editProfile',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const EditProfileScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings/change-password',
      name: 'changePassword',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ChangePasswordScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings/privacy-policy',
      name: 'privacyPolicy',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const PrivacyPolicyScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings/terms-conditions',
      name: 'termsConditions',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const TermsConditionsScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings/contact-support',
      name: 'contactSupport',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ContactSupportScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings/rate-app',
      name: 'rateApp',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const RateAppScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/medication/confirm',
      name: 'medicationConfirm',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const MedicationConfirmScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/medication/success/:streak',
      name: 'medicationSuccess',
      pageBuilder: (context, state) {
        final streak = int.tryParse(state.pathParameters['streak'] ?? '0') ?? 0;
        return CustomTransitionPage(
          child: MedicationSuccessScreen(streak: streak),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ).drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/medication/failed',
      name: 'medicationFailed',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const MedicationFailedScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/symptoms/log',
      name: 'symptomsLog',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SymptomInputScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/education',
      name: 'education',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const EducationListScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/education/:id',
      name: 'educationDetail',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          child: EducationDetailScreen(articleId: id),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/control/detail/:id',
      name: 'controlDetail',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ControlDetailScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/report/:yearMonth',
      name: 'report',
      pageBuilder: (context, state) {
        final yearMonth = state.pathParameters['yearMonth'] ?? '';
        return CustomTransitionPage(
          child: MonthlyReportScreen(yearMonth: yearMonth),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/notification-history',
      name: 'notificationHistory',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const NotificationHistoryScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/side-effects/log',
      name: 'sideEffectsLog',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SideEffectDetailScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ).drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
            child: child,
          );
        },
      ),
    ),
  ],
);
