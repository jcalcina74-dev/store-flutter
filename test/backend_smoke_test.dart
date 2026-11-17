import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:store/core/config/app_config.dart';
import 'package:store/core/network/api_client.dart';
import 'package:store/core/realtime/catalog_events.dart';
import 'package:store/features/auth/application/admin_session.dart';
import 'package:store/features/catalog/data/store_repository.dart';
import 'package:store/features/catalog/domain/product.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_BACKEND_SMOKE');
  test(
    'Contrato real: sesión, CRUD, imágenes WebP y SSE',
    () async {
      final config = AppConfig(baseUrl: Uri.parse('http://127.0.0.1:18080'));
      final session = AdminSession();
      final api = ApiClient(config, session);
      final repository = StoreRepository(api);
      final events = CatalogEvents(config);
      try {
        final synchronized = events.changes.first.timeout(
          const Duration(seconds: 10),
        );
        events.start();
        await synchronized;
        expect(
          await session.signIn(repository, 'smokeadmin', 'Smoke-backend-2026!'),
          isTrue,
        );
        final brandEvent = events.changes.first.timeout(
          const Duration(seconds: 5),
        );
        final brand = await repository.saveBrand('Flutter Smoke');
        await brandEvent;
        final productEvent = events.changes.first.timeout(
          const Duration(seconds: 5),
        );
        final product = await repository.saveProduct({
          'marcaId': brand.id,
          'modelo': 'Flutter Phone',
          'descripcion': 'Prueba de integración',
          'precio': 2300.50,
          'stock': 3,
          'ramGb': 8,
          'almacenamientoGb': 256,
          'pantallaPulgadas': 6.5,
          'bateriaMah': 5000,
          'sistemaOperativo': 'Android',
          'color': 'Negro',
          'activo': true,
        });
        await productEvent;
        final listed = await repository.products(const CatalogQuery());
        expect(listed.items.any((p) => p.id == product.id), isTrue);
        final bytes = Uint8List.fromList(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9XYAAAAASUVORK5CYII=',
          ),
        );
        final imageEvent = events.changes.first.timeout(
          const Duration(seconds: 5),
        );
        final image = await repository.uploadImage(
          product.id,
          bytes,
          'foto.png',
          0,
        );
        await imageEvent;
        final detail = await repository.product(product.id);
        expect(detail.images.single.id, image.id);
        final updateEvent = events.changes.first.timeout(
          const Duration(seconds: 5),
        );
        await repository.saveProduct({
          'marcaId': brand.id,
          'modelo': 'Flutter Phone',
          'descripcion': 'Actualizado',
          'precio': 2100,
          'stock': 1,
          'ramGb': 8,
          'almacenamientoGb': 256,
          'pantallaPulgadas': 6.5,
          'bateriaMah': 5000,
          'sistemaOperativo': 'Android',
          'color': 'Negro',
          'activo': false,
        }, id: product.id);
        await updateEvent;
        expect((await repository.products(const CatalogQuery())).total, 0);
        expect(
          (await repository.product(product.id, admin: true)).active,
          isFalse,
        );
        await repository.deleteImage(product.id, image.id);
        await repository.deleteProduct(product.id);
        await repository.deleteBrand(brand.id);
        expect(await repository.brands(), isEmpty);
      } finally {
        events.dispose();
        api.dispose();
        session.dispose();
      }
    },
    skip: !enabled,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
