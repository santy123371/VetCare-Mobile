import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/pets/screens/pets_list_screen.dart';
import '../../features/pets/screens/pet_form_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.isAuthenticated;
      final isLogin = state.matchedLocation == '/login';

      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/pets', builder: (_, __) => const PetsListScreen()),
      GoRoute(path: '/pets/new', builder: (_, __) => const PetFormScreen()),
      GoRoute(
        path: '/pets/:id/edit',
        builder: (context, state) =>
            PetFormScreen(petId: state.pathParameters['id']),
      ),
    ],
  );
});
