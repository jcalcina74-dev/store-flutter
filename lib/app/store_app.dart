import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/realtime/catalog_events.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/application/admin_session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/catalog/data/store_repository.dart';
import '../features/catalog/presentation/catalog_screen.dart';
import '../features/catalog/presentation/detail_screen.dart';
import '../features/admin/presentation/admin_screen.dart';
import '../features/admin/presentation/product_editor_screen.dart';

class StoreApp extends StatefulWidget {
  const StoreApp({
    required this.repository,
    required this.session,
    required this.events,
    this.initialLocation = '/',
    super.key,
  });
  final StoreRepository repository;
  final AdminSession session;
  final CatalogEvents events;
  final String initialLocation;
  @override
  State<StoreApp> createState() => _StoreAppState();
}

class _StoreAppState extends State<StoreApp> with WidgetsBindingObserver {
  late final GoRouter router;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    router = GoRouter(
      initialLocation: widget.initialLocation,
      refreshListenable: widget.session,
      redirect: (context, state) {
        final admin = state.uri.path.startsWith('/admin');
        if (admin && !widget.session.authenticated) return '/acceso';
        if (state.uri.path == '/acceso' && widget.session.authenticated) {
          return '/admin';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, state) => const CatalogScreen()),
        GoRoute(
          path: '/celular/:id',
          builder: (_, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return id == null
                ? const _NotFound()
                : DetailScreen(key: ValueKey(id), id: id);
          },
        ),
        GoRoute(path: '/acceso', builder: (_, state) => const LoginScreen()),
        GoRoute(
          path: '/admin',
          builder: (_, state) => const AdminScreen(),
          routes: [
            GoRoute(
              path: 'nuevo',
              builder: (_, state) => const ProductEditorScreen(),
            ),
            GoRoute(
              path: 'producto/:id',
              builder: (_, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                return id == null
                    ? const _NotFound()
                    : ProductEditorScreen(key: ValueKey(id), id: id);
              },
            ),
          ],
        ),
      ],
      errorBuilder: (_, state) => const _NotFound(),
    );
    widget.events.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.events.start();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      widget.events.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    widget.events.dispose();
    widget.session.dispose();
    widget.repository.api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<StoreRepository>.value(value: widget.repository),
      ChangeNotifierProvider<AdminSession>.value(value: widget.session),
      ChangeNotifierProvider<CatalogEvents>.value(value: widget.events),
    ],
    child: MaterialApp.router(
      title: 'NOVA · Celulares',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: router,
      locale: const Locale('es', 'BO'),
      supportedLocales: const [Locale('es', 'BO')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  );
}

class _NotFound extends StatelessWidget {
  const _NotFound();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No encontramos esta página.'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Volver al catálogo'),
          ),
        ],
      ),
    ),
  );
}
