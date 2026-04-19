import 'package:go_router/go_router.dart';

import '../utils/app_logger.dart';
import '../../viewmodels/session_view_model.dart';
import '../../views/screens/auth/auth_screen.dart';
import '../../views/screens/onboarding/onboarding_screen.dart';
import '../../views/screens/profile/profile_edit_screen.dart';
import '../../views/screens/splash/splash_screen.dart';
import '../../views/screens/trip_result/trip_result_screen.dart';
import '../../views/shells/main_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const main = '/main';
  static const trip = '/trip/:tripId';
  static const profileEdit = '/profile/edit';
}

GoRouter buildRouter(SessionViewModel session) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (context, state) {
      final path = state.fullPath ?? AppRoutes.splash;
      AppLogger.info(
        'Router redirect check: path=$path, '
        'ready=${session.isReady}, auth=${session.isAuthenticated}, '
        'onboarding=${session.onboardingComplete}',
      );

      if (!session.isReady) {
        final target = path == AppRoutes.splash ? null : AppRoutes.splash;
        if (target != null) {
          AppLogger.info('Redirecting to splash until session ready');
        }
        return target;
      }
      if (!session.isAuthenticated) {
        final target = path == AppRoutes.auth ? null : AppRoutes.auth;
        if (target != null) {
          AppLogger.info('Redirecting to auth because user unauthenticated');
        }
        return target;
      }
      if (!session.onboardingComplete) {
        final target = path == AppRoutes.onboarding
            ? null
            : AppRoutes.onboarding;
        if (target != null) {
          AppLogger.info(
            'Redirecting to onboarding because profile incomplete',
          );
        }
        return target;
      }

      const gated = {AppRoutes.splash, AppRoutes.auth, AppRoutes.onboarding};
      if (gated.contains(path)) {
        AppLogger.info('Redirecting to main from gated route');
        return AppRoutes.main;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.auth, builder: (_, __) => const AuthScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.main, builder: (_, __) => const MainShell()),
      GoRoute(
        path: AppRoutes.trip,
        builder: (_, state) =>
            TripResultScreen(tripId: state.pathParameters['tripId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (_, __) => const ProfileEditScreen(),
      ),
    ],
  );
}
