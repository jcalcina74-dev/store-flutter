import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store/app/store_app.dart';
import 'package:store/features/auth/application/admin_session.dart';

import 'support/fakes.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  Future<void> mount(
    WidgetTester tester, {
    String location = '/',
    bool admin = false,
  }) async {
    final session = AdminSession();
    final repo = FakeRepository(session);
    if (admin) await session.signIn(repo, 'admin', 'password-de-prueba');
    await tester.pumpWidget(
      StoreApp(
        repository: repo,
        session: session,
        events: TestEvents(),
        initialLocation: location,
      ),
    );
    await tester.pumpAndSettle();
  }

  void viewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Acceso discreto por pulsación larga y rutas protegidas', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    await mount(tester);
    expect(find.text('Ingresar al panel'), findsNothing);
    await tester.longPress(find.byKey(const Key('store-logo')));
    await tester.pumpAndSettle();
    expect(find.text('Ingresar al panel'), findsOneWidget);
    expect(find.text('Tu catálogo, al día.'), findsNothing);
  });

  testWidgets('El inicio de sesión abre el panel sin guardar credenciales', (
    tester,
  ) async {
    viewport(tester, const Size(1000, 900));
    await mount(tester, location: '/admin');
    await tester.enterText(find.byKey(const Key('admin-user')), 'admin');
    await tester.enterText(
      find.byKey(const Key('admin-password')),
      'password-de-prueba',
    );
    await tester.tap(find.text('Ingresar al panel'));
    await tester.pumpAndSettle();
    expect(find.text('Tu catálogo, al día.'), findsOneWidget);
    expect(find.text('Nuevo celular'), findsOneWidget);
  });

  for (final width in [320.0, 800.0, 1440.0]) {
    testWidgets('Catálogo sin desbordamientos a $width px', (tester) async {
      viewport(tester, Size(width, 1000));
      await mount(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Explora el catálogo'), findsOneWidget);
    });
  }

  testWidgets('Texto ampliado mantiene el catálogo utilizable', (tester) async {
    viewport(tester, const Size(390, 1000));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Detalle responsive con especificaciones reales', (tester) async {
    viewport(tester, const Size(390, 1000));
    await mount(tester, location: '/celular/1');
    expect(find.text('Galaxy S26 Ultra'), findsOneWidget);
    expect(find.text('Conócelo en detalle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El editor valida precios antes de enviar', (tester) async {
    viewport(tester, const Size(1000, 1000));
    await mount(tester, location: '/admin/nuevo', admin: true);
    await tester.enterText(
      find.byKey(const ValueKey('field-modelo')),
      'Mi celular',
    );
    await tester.enterText(find.byKey(const ValueKey('field-precio')), '0');
    await tester.tap(find.text('Guardar celular'));
    await tester.pumpAndSettle();
    expect(find.text('Debe ser mayor que cero'), findsOneWidget);
  });

  testWidgets('Catálogo móvil: revisión visual', (tester) async {
    viewport(tester, const Size(390, 1100));
    await mount(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/catalog_mobile.png'),
    );
  });
  testWidgets('Catálogo escritorio: revisión visual', (tester) async {
    viewport(tester, const Size(1440, 1100));
    await mount(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/catalog_desktop.png'),
    );
  });

  testWidgets('Guardar un celular válido abre su editor de imágenes', (
    tester,
  ) async {
    viewport(tester, const Size(1000, 1100));
    await mount(tester, location: '/admin/nuevo', admin: true);
    await tester.enterText(
      find.byKey(const ValueKey('field-modelo')),
      'Nuevo celular',
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-precio')),
      '2500.50',
    );
    await tester.tap(find.text('Guardar celular'));
    await tester.pumpAndSettle();
    expect(find.text('Editar celular'), findsOneWidget);
    expect(find.text('Añadir imagen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Panel móvil: revisión visual', (tester) async {
    viewport(tester, const Size(390, 1100));
    await mount(tester, location: '/admin', admin: true);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/admin_mobile.png'),
    );
  });
  testWidgets('Editor escritorio: revisión visual', (tester) async {
    viewport(tester, const Size(1200, 1100));
    await mount(tester, location: '/admin/nuevo', admin: true);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/editor_desktop.png'),
    );
  });
  testWidgets('Detalle escritorio: revisión visual', (tester) async {
    viewport(tester, const Size(1200, 1100));
    await mount(tester, location: '/celular/1');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/detail_desktop.png'),
    );
  });
}
