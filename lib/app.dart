import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'services/auth_service.dart';
import 'services/firebase_bootstrap_service.dart';
import 'services/preferences_service.dart';
import 'services/profile_service.dart';
import 'viewmodels/session_view_model.dart';
import 'viewmodels/theme_view_model.dart';

/// Global scroll behaviour — bouncing physics on every platform.
class _BouncingScrollBehaviour extends ScrollBehavior {
  const _BouncingScrollBehaviour();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class SnapbackRoot extends StatelessWidget {
  const SnapbackRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = PreferencesService();
    return MultiProvider(
      providers: [
        Provider<PreferencesService>.value(value: preferences),
        Provider<FirebaseBootstrapService>(
          create: (_) => FirebaseBootstrapService(),
        ),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ProfileService>(create: (_) => ProfileService()),
        ChangeNotifierProvider<ThemeViewModel>(
          create: (_) =>
              ThemeViewModel(preferencesService: preferences)..load(),
        ),
        ChangeNotifierProvider<SessionViewModel>(
          create: (ctx) => SessionViewModel(
            bootstrapService: ctx.read<FirebaseBootstrapService>(),
            authService: ctx.read<AuthService>(),
            profileService: ctx.read<ProfileService>(),
            preferencesService: preferences,
          )..initialize(),
        ),
      ],
      child: const _App(),
    );
  }
}

class _App extends StatefulWidget {
  const _App();

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  late final _router = buildRouter(context.read<SessionViewModel>());

  @override
  void initState() {
    super.initState();
    AppLogger.info('Root app state initialized');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeViewModel>();
    final session = context.watch<SessionViewModel>();
    AppLogger.info(
      'MaterialApp rebuild: theme=${theme.themeMode.name}, '
      'ready=${session.isReady}, auth=${session.isAuthenticated}, '
      'onboarding=${session.onboardingComplete}',
    );

    return MaterialApp.router(
      title: 'SNAPback',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.themeMode,
      locale: session.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es'), Locale('zh')],
      scrollBehavior: const _BouncingScrollBehaviour(),
      routerConfig: _router,
    );
  }
}
