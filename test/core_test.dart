import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:store/core/config/app_config.dart';
import 'package:store/core/network/api_client.dart';
import 'package:store/core/network/api_exception.dart';
import 'package:store/core/realtime/sse_decoder.dart';
import 'package:store/features/auth/application/admin_session.dart';
import 'package:store/features/catalog/application/catalog_controller.dart';
import 'package:store/features/catalog/application/detail_controller.dart';
import 'package:store/features/catalog/data/store_repository.dart';
import 'package:store/features/catalog/domain/product.dart';

import 'support/fakes.dart';

void main() {
  test('SSE respeta UTF-8, comentarios, bloques y datos multilínea', () async {
    final bytes = utf8.encode(
      ':keep-alive\r\nevent: catalogo-actualizado\r\nid: 4\r\ndata: línea uno\r\ndata: dos\r\n\r\ndata: incompleto',
    );
    final chunks = [
      bytes.sublist(0, 13),
      bytes.sublist(13, 50),
      bytes.sublist(50),
    ];
    final result = await Stream<List<int>>.fromIterable(chunks)
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(const SseDecoder())
        .toList();
    expect(result, hasLength(1));
    expect(result.single.name, 'catalogo-actualizado');
    expect(result.single.id, '4');
    expect(result.single.data, 'línea uno\ndos');
  });

  test(
    'La API pública no adjunta credenciales y la administrativa sí',
    () async {
      final session = AdminSession();
      final requests = <http.Request>[];
      final client = ApiClient(
        testConfig,
        session,
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            '{"contenido":[],"pagina":0,"totalPaginas":0,"totalElementos":0}',
            200,
          );
        }),
      );
      final repo = StoreRepository(client);
      await session.signIn(repo, 'admin', 'password-de-prueba');
      await client.request('GET', '/api/catalogo/celulares');
      await client.request(
        'POST',
        '/api/admin/marcas',
        admin: true,
        body: {'nombre': 'Nokia'},
      );
      expect(requests[1].headers.containsKey('Authorization'), isFalse);
      expect(requests[2].headers['Authorization'], startsWith('Basic '));
      expect(requests[2].headers['X-Admin-Request'], 'true');
      expect(jsonDecode(requests[2].body), {'nombre': 'Nokia'});
      client.dispose();
      session.dispose();
    },
  );

  test('Un 401 invalida la sesión y no se reintenta una escritura', () async {
    final session = AdminSession();
    var calls = 0;
    final client = ApiClient(
      testConfig,
      session,
      client: MockClient((request) async {
        calls++;
        return http.Response(
          calls == 1 ? '{}' : '{"detail":"No"}',
          calls == 1 ? 200 : 401,
        );
      }),
    );
    await session.signIn(StoreRepository(client), 'admin', 'password');
    await expectLater(
      client.request('DELETE', '/api/admin/celulares/1', admin: true),
      throwsA(isA<ApiException>()),
    );
    expect(session.authenticated, isFalse);
    expect(calls, 2);
    client.dispose();
    session.dispose();
  });

  test(
    'La configuración rechaza URLs con credenciales e imágenes externas',
    () {
      expect(
        () => AppConfig(baseUrl: Uri.parse('https://user:pass@host')),
        throwsArgumentError,
      );
      expect(
        () => testConfig.imageUrl('https://otro.test/foto.webp'),
        throwsFormatException,
      );
      expect(
        testConfig.imageUrl('/api/media/1'),
        'http://localhost:8080/api/media/1',
      );
    },
  );

  test(
    'Descarta la respuesta de una búsqueda anterior y conserva el filtro',
    () async {
      final session = AdminSession(), events = TestEvents();
      final repo = FakeRepository(session);
      final first = Completer<ProductPage>();
      repo.onProducts = (query) => repo.seen.length == 1
          ? first.future
          : Future.value(
              ProductPage(
                items: [sampleProduct(2, brandId: 2)],
                page: query.page,
                pages: 1,
                total: 1,
              ),
            );
      final controller = CatalogController(repo, events);
      final done = controller.refresh();
      controller.selectBrand(2);
      first.complete(
        ProductPage(items: [sampleProduct(1)], page: 0, pages: 1, total: 1),
      );
      await done;
      expect(controller.query.brandId, 2);
      expect(controller.products.single.id, 2);
      controller.dispose();
      events.dispose();
      repo.api.dispose();
      session.dispose();
    },
  );

  test('Un aviso durante la carga deja una recarga pendiente', () async {
    final session = AdminSession(), events = TestEvents();
    final repo = FakeRepository(session);
    final first = Completer<ProductPage>();
    repo.onProducts = (q) => repo.seen.length == 1
        ? first.future
        : Future.value(
            ProductPage(items: [sampleProduct(7)], page: 0, pages: 1, total: 1),
          );
    final controller = CatalogController(repo, events);
    final done = controller.refresh();
    events.emit();
    first.complete(
      ProductPage(items: [sampleProduct(1)], page: 0, pages: 1, total: 1),
    );
    await done;
    expect(repo.seen, hasLength(2));
    expect(controller.products.single.id, 7);
    controller.dispose();
    events.dispose();
    repo.api.dispose();
    session.dispose();
  });

  test('Si desaparece la última página, consulta la última válida', () async {
    final session = AdminSession(), events = TestEvents();
    final repo = FakeRepository(session);
    repo.items = List.generate(60, (i) => sampleProduct(i + 1));
    final controller = CatalogController(repo, events);
    await controller.refresh();
    repo.items = repo.items.take(18).toList();
    controller.goToPage(4);
    await Future<void>.delayed(Duration.zero);
    expect(controller.query.page, 1);
    expect(controller.products, hasLength(6));
    controller.dispose();
    events.dispose();
    repo.api.dispose();
    session.dispose();
  });

  test('Un celular eliminado desaparece también del detalle abierto', () async {
    final session = AdminSession(), events = TestEvents();
    final repo = FakeRepository(session);
    final controller = DetailController(repo, events, 1);
    await controller.refresh();
    repo.onProduct = (_) async =>
        throw const ApiException('No encontrado', statusCode: 404);
    await controller.refresh();
    expect(controller.unavailable, isTrue);
    expect(controller.product, isNull);
    controller.dispose();
    events.dispose();
    repo.api.dispose();
    session.dispose();
  });
}
