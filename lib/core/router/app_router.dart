import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/map_screen.dart';
import '../../screens/area_upload_screen.dart';
import '../../screens/property_form_screen.dart';
import '../../screens/property_detail_screen.dart';
import '../../screens/category_manager_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/login', builder: (_, __) => LoginScreen()),

      GoRoute(path: '/register', builder: (_, __) => RegisterScreen()),

      GoRoute(path: '/dashboard', builder: (_, __) => const HomeScreen()),

      GoRoute(
        path: '/properties/:id/map',
        builder: (_, state) => MapScreen(
          propertyId: state.pathParameters['id']!,
          propertyName: state.uri.queryParameters['name'] ?? 'Propriedade',
        ),
      ),

      GoRoute(
        path: '/properties/:id/upload',
        builder: (_, state) => AreaUploadScreen(
          propertyId: state.pathParameters['id']!,
          propertyName: state.uri.queryParameters['name'] ?? 'Propriedade',
        ),
      ),

      GoRoute(
        path: '/properties/new',
        builder: (_, __) => const PropertyFormScreen(),
      ),

      GoRoute(
        path: '/properties/:id/edit',
        builder: (_, state) =>
            PropertyFormScreen(propertyId: state.pathParameters['id']!),
      ),

      GoRoute(
        path: '/properties/:id',
        builder: (_, state) =>
            PropertyDetailScreen(propertyId: state.pathParameters['id']!),
      ),

      GoRoute(
        path: '/properties/:id/categories',
        builder: (_, state) =>
            CategoryManagerScreen(propertyId: state.pathParameters['id']!),
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authProvider);

    if (authAsync.isLoading) return null;

    final isAuth = authAsync.valueOrNull?.isAuthenticated ?? false;

    final onAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isAuth && !onAuthRoute) return '/login';

    if (isAuth && onAuthRoute) return '/dashboard';
    return null;
  }
}
