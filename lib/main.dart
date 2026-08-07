import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:runearn/config/route/app_routes.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/di/injection_container.dart';
import 'package:runearn/core/network/finance_sync_listener.dart';
import 'package:runearn/core/observability/app_observability.dart';
import 'package:runearn/core/notifications/finance_notification_service.dart';
import 'package:runearn/core/notifications/finance_reminder_listener.dart';
import 'package:runearn/core/session/finance_session_cache.dart';
import 'package:runearn/core/security/local_data_cipher.dart';
import 'package:runearn/core/updates/app_update_startup_checker.dart';
import 'package:runearn/config/theme/app_theme.dart';
import 'package:runearn/config/theme/theme_cubit.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_event.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_state.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_event.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_state.dart';
import 'package:runearn/feature/transactions/data/datasources/local/transaction_db.dart';
import 'package:runearn/firebase_options.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await AppObservability.instance.initialize();
      AppObservability.instance.installGlobalErrorHandlers();
      await AppObservability.instance.trace('app_initialization', () async {
        await dotenv.load(fileName: ".env.dev");
        // 🔥 REQUIRED FOR WINDOWS / LINUX / MAC
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        }

        await LocalDataCipher.instance.initialize();
        await TransactionDB.init();
        await dependencyInjection();
        await sl<FinanceNotificationService>().initialize();
      });
      runApp(const MyApp());
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Unhandled zoned error: $error');
        debugPrintStack(stackTrace: stack);
      }
      unawaited(
        AppObservability.instance.recordError(error, stack, fatal: true),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  String getInitialRoute() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Routes.login;
    }
    return Routes.home;
  }

  List<Route<dynamic>> generateInitialRoutes(String _) {
    // A named initial route such as /home makes Flutter build both `/` and
    // `/home`. Since `/` falls back to the login view, pressing Back from the
    // dashboard could reveal login. Build only the resolved auth route.
    return <Route<dynamic>>[
      AppRoutes.onGenerateRoute(RouteSettings(name: getInitialRoute())),
    ];
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<CurrencyCubit>.value(value: sl<CurrencyCubit>()),
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => sl<ProfileBloc>()..add(LoadCurrentUserProfileEvent()),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            current is AuthLoading ||
            current is AuthAuthenticated ||
            current is AuthUnauthenticated,
        listener: (context, state) {
          if (state is AuthLoading) {
            // Authentication is changing. Purge user-scoped memory before a
            // login, registration, account switch, or logout can render.
            resetFinanceSessionCache(context.read<ProfileBloc>());
          }
          if (state is AuthAuthenticated) {
            unawaited(
              AppObservability.instance.setAuthenticationState(signedIn: true),
            );
            final profileBloc = context.read<ProfileBloc>();
            if (profileBloc.state is ProfileInitial ||
                profileBloc.state is ProfileEmpty ||
                profileBloc.state is ProfileFailure) {
              profileBloc.add(LoadCurrentUserProfileEvent());
            }
          }
          if (state is AuthUnauthenticated) {
            unawaited(
              AppObservability.instance.setAuthenticationState(signedIn: false),
            );
            resetFinanceSessionCache(context.read<ProfileBloc>());
          }
        },
        child: FinanceReminderListener(
          child: FinanceSyncListener(
            child: BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return AppUpdateStartupChecker(
                  navigatorKey: navigatorKey,
                  child: MaterialApp(
                    navigatorKey: navigatorKey,
                    debugShowCheckedModeBanner: false,
                    title: "RunEarn",
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
                    initialRoute: getInitialRoute(),
                    onGenerateInitialRoutes: generateInitialRoutes,
                    onGenerateRoute: AppRoutes.onGenerateRoute,
                    navigatorObservers: [
                      AppObservability.instance.navigatorObserver,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
