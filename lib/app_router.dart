import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/patient/presentation/pages/patient_dashboard_page.dart';
import 'features/doctor/presentation/pages/doctor_dashboard_page.dart';

class AppRouter {
  static GoRouter router(AuthBloc authBloc) => GoRouter(
        initialLocation: '/splash',
        redirect: (context, state) {
          final authState = authBloc.state;
          final loc = state.matchedLocation;

          final isPublic =
              loc == '/login' || loc == '/register' || loc == '/splash';

          if (authState is AuthAuthenticated) {
            if (isPublic) {
              return authState.user.isDoctor
                  ? '/doctor/dashboard'
                  : '/patient/dashboard';
            }
          }
          if (authState is AuthUnauthenticated) {
            if (!isPublic) return '/login';
          }
          return null;
        },
        refreshListenable: GoRouterRefreshStream(authBloc.stream),
        routes: [
          GoRoute(
            path: '/splash',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: SplashPage()),
          ),
          GoRoute(
            path: '/login',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: LoginPage()),
          ),
          GoRoute(
            path: '/register',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: RegisterPage()),
          ),
          GoRoute(
            path: '/patient/dashboard',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: PatientDashboardPage()),
          ),
          GoRoute(
            path: '/doctor/dashboard',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: DoctorDashboardPage()),
          ),
        ],
      );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    stream.listen((_) => notifyListeners());
  }
}
